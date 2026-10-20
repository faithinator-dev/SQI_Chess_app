import { createClient } from "npm:@supabase/supabase-js@2.95.0";
import { Chess } from "npm:chess.js@1.4.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const START_FEN =
  "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

type MoveRequest = {
  game_id?: string;
  uci?: string;
};

type GameRow = {
  id: string;
  status: string | null;

  current_fen: string | null;
  current_turn: string | null;

  white_player_id: string | null;
  black_player_id: string | null;

  white_time_ms: number | null;
  black_time_ms: number | null;

  increment_seconds: number | null;

  state_version: number | null;

  updated_at: string | null;
};

function jsonResponse(
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function normalizeFen(fen: string | null): string {
  if (!fen || fen.trim() === "" || fen === "startpos") {
    return START_FEN;
  }

  return fen;
}

function parseUci(uci: string) {
  const normalized = uci.trim().toLowerCase();

  if (!/^[a-h][1-8][a-h][1-8][qrbn]?$/.test(normalized)) {
    throw new Error("INVALID_UCI");
  }

  return {
    from: normalized.slice(0, 2),
    to: normalized.slice(2, 4),
    promotion: normalized.length === 5
      ? normalized.slice(4, 5)
      : undefined,
  };
}

function getPlayerColor(
  game: GameRow,
  userId: string,
): "white" | "black" | null {
  if (game.white_player_id === userId) {
    return "white";
  }

  if (game.black_player_id === userId) {
    return "black";
  }

  return null;
}

function getClockForColor(
  game: GameRow,
  color: "white" | "black",
): number {
  const value =
    color === "white"
      ? game.white_time_ms
      : game.black_time_ms;

  return Math.max(0, Number(value ?? 0));
}

function getIncrementMs(game: GameRow): number {
  return Math.max(
    0,
    Number(game.increment_seconds ?? 0) * 1000,
  );
}

function getElapsedMs(game: GameRow): number {
  if (!game.updated_at) {
    return 0;
  }

  const updatedAt = new Date(game.updated_at).getTime();

  if (!Number.isFinite(updatedAt)) {
    return 0;
  }

  return Math.max(0, Date.now() - updatedAt);
}

function getMoveNumber(chess: Chess): number {
  const fenParts = chess.fen().split(" ");

  const fullMoveNumber = Number(fenParts[5]);

  if (!Number.isFinite(fullMoveNumber) || fullMoveNumber < 1) {
    return 1;
  }

  return fullMoveNumber;
}

function getPlyFromFen(chess: Chess): number {
  const fenParts = chess.fen().split(" ");

  const fullMoveNumber = Number(fenParts[5]);
  const sideToMove = fenParts[1];

  if (
    !Number.isFinite(fullMoveNumber) ||
    fullMoveNumber < 1
  ) {
    return 1;
  }

  /*
   * After a move:
   *
   * black to move means White just moved.
   * white to move means Black just moved.
   *
   * Example:
   *
   * Initial position:
   * fullmove = 1, white to move
   *
   * After 1.e4:
   * fullmove = 1, black to move
   * ply = 1
   *
   * After 1...e5:
   * fullmove = 2, white to move
   * ply = 2
   */
  if (sideToMove === "b") {
    return (fullMoveNumber * 2) - 1;
  }

  return (fullMoveNumber * 2) - 2;
}

function getGameResult(
  chess: Chess,
  colorThatMoved: "white" | "black",
) {
  if (chess.isCheckmate()) {
    const winner = colorThatMoved;

    return {
      result: winner,
      termination_reason: "checkmate",
    };
  }

  if (chess.isStalemate()) {
    return {
      result: "draw",
      termination_reason: "stalemate",
    };
  }

  if (chess.isInsufficientMaterial()) {
    return {
      result: "draw",
      termination_reason: "insufficient_material",
    };
  }

  if (chess.isThreefoldRepetition()) {
    return {
      result: "draw",
      termination_reason: "threefold_repetition",
    };
  }

  if (chess.isDrawByFiftyMoves()) {
    return {
      result: "draw",
      termination_reason: "fifty_move_rule",
    };
  }

  return {
    result: null,
    termination_reason: null,
  };
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return String(error);
}

export default {
  async fetch(req: Request): Promise<Response> {
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: corsHeaders,
      });
    }

    if (req.method !== "POST") {
      return jsonResponse(
        {
          error: "METHOD_NOT_ALLOWED",
        },
        405,
      );
    }

    try {
      // ========================================================
      // 1. Environment
      // ========================================================

      const supabaseUrl =
        Deno.env.get("SUPABASE_URL");

      const serviceRoleKey =
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
        Deno.env.get("SUPABASE_SECRET_KEY");

      if (!supabaseUrl) {
        console.error("Missing SUPABASE_URL");

        return jsonResponse(
          {
            error: "SERVER_CONFIGURATION_ERROR",
          },
          500,
        );
      }

      if (!serviceRoleKey) {
        console.error(
          "Missing SUPABASE_SERVICE_ROLE_KEY or SUPABASE_SECRET_KEY",
        );

        return jsonResponse(
          {
            error: "SERVER_CONFIGURATION_ERROR",
          },
          500,
        );
      }

      // ========================================================
      // 2. Authorization
      // ========================================================

      const authorization =
        req.headers.get("Authorization");

      if (!authorization) {
        return jsonResponse(
          {
            error: "AUTH_REQUIRED",
          },
          401,
        );
      }

      if (!authorization.startsWith("Bearer ")) {
        return jsonResponse(
          {
            error: "INVALID_AUTHORIZATION",
          },
          401,
        );
      }

      const accessToken =
        authorization.substring("Bearer ".length).trim();

      if (!accessToken) {
        return jsonResponse(
          {
            error: "AUTH_REQUIRED",
          },
          401,
        );
      }

      // ========================================================
      // 3. Create privileged server client
      // ========================================================

      const supabaseAdmin = createClient(
        supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        },
      );

      // ========================================================
      // 4. Identify authenticated player
      // ========================================================

      const {
        data: {
          user,
        },
        error: authError,
      } = await supabaseAdmin.auth.getUser(accessToken);

      if (authError || !user) {
        console.error("Authentication failed:", authError);

        return jsonResponse(
          {
            error: "INVALID_SESSION",
          },
          401,
        );
      }

      // ========================================================
      // 5. Parse request
      // ========================================================

      let body: MoveRequest;

      try {
        body = await req.json();
      } catch {
        return jsonResponse(
          {
            error: "INVALID_JSON",
          },
          400,
        );
      }

      const gameId = body.game_id?.trim();
      const uci = body.uci?.trim().toLowerCase();

      if (!gameId) {
        return jsonResponse(
          {
            error: "GAME_ID_REQUIRED",
          },
          400,
        );
      }

      if (!uci) {
        return jsonResponse(
          {
            error: "UCI_REQUIRED",
          },
          400,
        );
      }

      // ========================================================
      // 6. Load current game
      // ========================================================

      const {
        data: game,
        error: gameError,
      } = await supabaseAdmin
        .from("games")
        .select(`
          id,
          status,
          current_fen,
          current_turn,
          white_player_id,
          black_player_id,
          white_time_ms,
          black_time_ms,
          increment_seconds,
          state_version,
          updated_at
        `)
        .eq("id", gameId)
        .maybeSingle();

      if (gameError) {
        console.error("Game lookup failed:", gameError);

        return jsonResponse(
          {
            error: "GAME_LOOKUP_FAILED",
          },
          500,
        );
      }

      if (!game) {
        return jsonResponse(
          {
            error: "GAME_NOT_FOUND",
          },
          404,
        );
      }

      const typedGame = game as GameRow;

      // ========================================================
      // 7. Verify active game
      // ========================================================

      if (typedGame.status !== "active") {
        return jsonResponse(
          {
            error: "GAME_NOT_ACTIVE",
            status: typedGame.status,
          },
          409,
        );
      }

      // ========================================================
      // 8. Determine player color
      // ========================================================

      const playerColor =
        getPlayerColor(typedGame, user.id);

      if (!playerColor) {
        return jsonResponse(
          {
            error: "NOT_A_GAME_PLAYER",
          },
          403,
        );
      }

      // ========================================================
      // 9. Verify turn
      // ========================================================

      if (typedGame.current_turn !== playerColor) {
        return jsonResponse(
          {
            error: "NOT_YOUR_TURN",
            current_turn: typedGame.current_turn,
          },
          409,
        );
      }

      // ========================================================
      // 10. Require state version
      // ========================================================

      const expectedStateVersion =
        Number(typedGame.state_version ?? 0);

      if (
        !Number.isSafeInteger(expectedStateVersion) ||
        expectedStateVersion < 0
      ) {
        console.error(
          "Invalid state_version:",
          typedGame.state_version,
        );

        return jsonResponse(
          {
            error: "INVALID_GAME_STATE_VERSION",
          },
          500,
        );
      }

      // ========================================================
      // 11. Load authoritative FEN
      // ========================================================

      const expectedFen =
        normalizeFen(typedGame.current_fen);

      // ========================================================
      // 12. Verify chess position
      // ========================================================

      let chess: Chess;

      try {
        chess = new Chess(expectedFen);
      } catch (error) {
        console.error(
          "Invalid game FEN:",
          error,
        );

        return jsonResponse(
          {
            error: "INVALID_GAME_POSITION",
          },
          500,
        );
      }

      // ========================================================
      // 13. Verify chess.js turn matches database turn
      // ========================================================

      const chessTurn =
        chess.turn() === "w"
          ? "white"
          : "black";

      if (chessTurn !== playerColor) {
        console.error(
          "Turn mismatch:",
          {
            database: typedGame.current_turn,
            chess: chessTurn,
            player: playerColor,
          },
        );

        return jsonResponse(
          {
            error: "GAME_TURN_MISMATCH",
          },
          500,
        );
      }

      // ========================================================
      // 14. Parse UCI
      // ========================================================

      let parsedMove;

      try {
        parsedMove = parseUci(uci);
      } catch {
        return jsonResponse(
          {
            error: "INVALID_UCI",
          },
          400,
        );
      }

      // ========================================================
      // 15. Check player's clock BEFORE allowing move
      // ========================================================

      const currentClock =
        getClockForColor(
          typedGame,
          playerColor,
        );

      const elapsedMs =
        getElapsedMs(typedGame);

      const clockAfterMoveBeforeIncrement =
        Math.max(
          0,
          currentClock - elapsedMs,
        );

      if (clockAfterMoveBeforeIncrement <= 0) {
        return jsonResponse(
          {
            error: "TIMEOUT",
            message: "Your clock expired before this move was accepted.",
          },
          409,
        );
      }

      // ========================================================
      // 16. Validate and make chess move
      // ========================================================

      let moveResult;

      try {
        moveResult = chess.move({
          from: parsedMove.from,
          to: parsedMove.to,
          ...(parsedMove.promotion
            ? {
                promotion: parsedMove.promotion,
              }
            : {}),
        });
      } catch (error) {
        console.error(
          "Illegal chess move:",
          error,
        );

        return jsonResponse(
          {
            error: "ILLEGAL_MOVE",
          },
          422,
        );
      }

      if (!moveResult) {
        return jsonResponse(
          {
            error: "ILLEGAL_MOVE",
          },
          422,
        );
      }

      // ========================================================
      // 17. Authoritative SAN
      // ========================================================

      const san = moveResult.san;

      // ========================================================
      // 18. Authoritative FEN
      // ========================================================

      const fenAfter = chess.fen();

      // ========================================================
      // 19. Clock calculation
      // ========================================================

      const incrementMs =
        getIncrementMs(typedGame);

      const remainingTimeMs =
        Math.max(
          0,
          clockAfterMoveBeforeIncrement + incrementMs,
        );

      // ========================================================
      // 20. Determine move numbers
      // ========================================================

      const moveNumber =
        getMoveNumber(chess);

      const ply =
        getPlyFromFen(chess);

      // ========================================================
      // 21. Determine chess result
      // ========================================================

      const chessResult =
        getGameResult(
          chess,
          playerColor,
        );

      // ========================================================
      // 22. Commit atomically in PostgreSQL
      //
      // This is the important security step.
      //
      // The database will:
      //
      // - lock the game row
      // - verify state_version
      // - verify FEN
      // - verify turn
      // - verify player
      // - insert the move
      // - update the game
      // - increment state_version
      //
      // If another request changed the game first,
      // this RPC rejects the stale request.
      // ========================================================

      const {
        data: committed,
        error: commitError,
      } = await supabaseAdmin.rpc(
        "commit_validated_move",
        {
          p_game_id: gameId,
          p_user_id: user.id,

          p_expected_state_version:
            expectedStateVersion,

          p_expected_fen:
            expectedFen,

          p_expected_turn:
            playerColor,

          p_uci:
            uci,

          p_san:
            san,

          p_fen_after:
            fenAfter,

          p_color:
            playerColor,

          p_move_number:
            moveNumber,

          p_ply:
            ply,

          p_remaining_time_ms:
            remainingTimeMs,

          p_result:
            chessResult.result,

          p_termination_reason:
            chessResult.termination_reason,
        },
      );

      // ========================================================
      // 23. Handle atomic commit errors
      // ========================================================

      if (commitError) {
        console.error(
          "Atomic move commit failed:",
          commitError,
        );

        const databaseMessage =
          commitError.message ?? "";

        if (
          databaseMessage.includes("Game state is stale")
        ) {
          return jsonResponse(
            {
              error: "STALE_GAME_STATE",
              message:
                "The game changed before this move was committed. Refresh the latest game state and try again.",
            },
            409,
          );
        }

        if (
          databaseMessage.includes("It is not this player's turn")
        ) {
          return jsonResponse(
            {
              error: "NOT_YOUR_TURN",
            },
            409,
          );
        }

        if (
          databaseMessage.includes("Move already committed")
        ) {
          return jsonResponse(
            {
              error: "MOVE_ALREADY_COMMITTED",
            },
            409,
          );
        }

        if (
          databaseMessage.includes("Game is not active")
        ) {
          return jsonResponse(
            {
              error: "GAME_NOT_ACTIVE",
            },
            409,
          );
        }

        return jsonResponse(
          {
            error: "MOVE_COMMIT_FAILED",
          },
          500,
        );
      }

      // ========================================================
      // 24. Success
      // ========================================================

      return jsonResponse(
        {
          success: true,

          game_id: gameId,

          move: {
            uci,
            san,
            fen_after: fenAfter,
            color: playerColor,
            move_number: moveNumber,
            ply,
            remaining_time_ms:
              remainingTimeMs,
          },

          result:
            chessResult.result,

          termination_reason:
            chessResult.termination_reason,

          state_version:
            expectedStateVersion + 1,

          committed,
        },
        200,
      );
    } catch (error) {
      console.error(
        "submit-move unexpected error:",
        error,
      );

      return jsonResponse(
        {
          error: "INTERNAL_SERVER_ERROR",
        },
        500,
      );
    }
  },
};