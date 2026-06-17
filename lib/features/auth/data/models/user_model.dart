import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
  });

  /// Builds the user from the Supabase session's [User] object
  /// (id, email, metadata) + the `role` returned by `POST /auth/role`.
  factory UserModel.fromSupabaseUser(
      supabase.User supabaseUser,
      String role,
      ) {
    final metadata = supabaseUser.userMetadata ?? {};
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: metadata['full_name'] as String? ?? '',
      phoneNumber: metadata['phone_number'] as String?,
      role: role,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, phoneNumber, role];
}