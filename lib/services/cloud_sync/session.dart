part of '../cloud_sync_service.dart';

Future<UserCredential?> _signIn() => GoogleAccountService.signIn();

Future<void> _signOut() => GoogleAccountService.signOut();
