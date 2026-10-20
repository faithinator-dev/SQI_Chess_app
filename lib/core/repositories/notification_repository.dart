import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<NotificationModel>> getCurrentNotifications({
    int limit = 30,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return [];
    }

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return data
        .map(
          (item) => NotificationModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return 0;
    }

    return await _client
        .from('notifications')
        .count(CountOption.exact)
        .eq('user_id', user.id)
        .isFilter('read_at', null);
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllAsRead() async {
    await _client.rpc('mark_all_notifications_read');
  }

  RealtimeChannel watchCurrentUser({required VoidCallback onChanged}) {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final channel = _client
        .channel('notifications:${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) {
            onChanged();
          },
        );

    channel.subscribe();

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
