# Friends and online challenges

This document explains how the friend connection works in SQI Chess Club.

## What players can do

1. Open **Profile > Friends**.
2. Search for another player's username.
3. Press **Add** to send a friend request.
4. The other player opens **Profile > Friends** and accepts the request.
5. The accepted friend appears under **My friends**.
6. Press **Challenge** beside a friend to create an online game invitation.
7. The invited player opens **Profile > Friends**, sees **Game invitations**, and presses **Play**.
8. Both players are taken into the same online chess game. The inviter is White and the invited player is Black.

The invitation is restricted to the selected friend. A different account cannot join it.

## Friend request rules

- A player cannot add their own account.
- A friend relationship is stored once for the pair, regardless of who sent the request.
- Requests can be accepted or declined.
- Only the request recipient can accept or decline a pending request.
- Only accepted friends can be challenged.
- Removing a friend is supported by the database function and can be added to the UI without changing the game model.

## Quick Match versus Friends

**Quick Match** is anonymous matchmaking. Both players must press **Find Match** and the server pairs compatible queue entries.

**Friends** is an intentional connection. Players first accept a friend request, then the inviter sends a private game invitation. The invited player does not need to press Quick Match.

## Database setup

Apply migrations in filename order, including:

- `20261103000200_friends.sql`

The migration creates:

- `friend_requests`
- request and response RPC functions
- friend removal RPC
- the `games.invited_player_id` field
- direct friend challenge support in `create_friend_game`
- invitation access in the games read policy

Supabase Realtime is not required for the initial friend screen because the screen refreshes on open and pull-to-refresh. The online chess board continues to use the existing realtime `games` channel after both players enter the game.

## Security model

The client never directly changes a friend request status. It calls security-definer RPC functions that verify the authenticated user and the request recipient. Game creation verifies that the target is an accepted friend, and joining verifies that the current user is the invited player.

## If a friend does not appear

1. Confirm both players are signed in.
2. Confirm the username is exact enough to find the account.
3. Ask the recipient to refresh the Friends page.
4. Confirm the request was accepted.
5. Check that the migration was applied in Supabase.
