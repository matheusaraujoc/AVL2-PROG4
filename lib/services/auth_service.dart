import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final String apiKey = 'AIzaSyAqYnKmOM_YrcVHGWxFunzLRn-xTAbkXZA';
  final String dbUrl = 'https://reservas-f39b7-default-rtdb.firebaseio.com';

  static String? currentUserId;
  static String? currentUserName;
  static String? currentUserEmail;
  static bool isAdmin = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '627683823181-1k92qfompdd7a3e49pucssi4goucv06v.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // No método checkIfUserIsAdmin do AuthService
  Future<bool> checkIfUserIsAdmin(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$dbUrl/admins/$userId.json'),
      );
      // Adicione este print
      print('Verificando admin para userId: $userId');
      print('Resposta: ${response.body}');
      return json.decode(response.body) == true;
    } catch (e) {
      print('Erro ao verificar admin: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
    currentUserName = prefs.getString('userName');
    currentUserEmail = prefs.getString('userEmail');

    // Adicione esta verificação
    if (currentUserId != null) {
      isAdmin = await checkIfUserIsAdmin(currentUserId!);
    }
  }

  Future<void> _saveUserData(
      String userId, String userName, String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userName', userName);
    await prefs.setString('userEmail', userEmail);
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Iniciando tentativa de login...');
      final url =
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
      print('URL da requisição: $url');

      final body = {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      };
      print('Dados enviados: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Status code da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final userId = responseData['localId'];
        print('Login bem sucedido. UserId: $userId');

        // Busca dados adicionais do usuário
        print('Buscando dados do usuário no Realtime Database...');
        final userDataResponse = await http.get(
          Uri.parse('$dbUrl/users/$userId.json'),
        );

        print('Status code dados usuário: ${userDataResponse.statusCode}');
        print('Dados do usuário: ${userDataResponse.body}');

        if (userDataResponse.statusCode == 200) {
          final userData = json.decode(userDataResponse.body);

          currentUserId = userId;
          currentUserName = userData['username'];
          currentUserEmail = email;
          isAdmin = await checkIfUserIsAdmin(userId);

          print('Dados do usuário processados:');
          print('Username: $currentUserName');
          print('Email: $currentUserEmail');
          print('IsAdmin: $isAdmin');

          await _saveUserData(userId, userData['username'], email);

          return {
            ...responseData,
            'username': userData['username'],
            'userData': userData,
          };
        } else {
          print('Erro ao buscar dados do usuário: ${userDataResponse.body}');
          throw 'Erro ao buscar dados do usuário';
        }
      } else {
        print('Erro no login: ${responseData['error']}');
        throw responseData['error']['message'];
      }
    } catch (e) {
      print('Exceção capturada no login: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signup(
      String email, String password, String username) async {
    try {
      final authResponse = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final authData = json.decode(authResponse.body);

      if (authResponse.statusCode != 200) {
        throw authData['error']['message'];
      }

      final userId = authData['localId'];

      try {
        final userDataResponse = await http.put(
          Uri.parse('$dbUrl/users/$userId.json'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'email': email,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );

        if (userDataResponse.statusCode != 200) {
          print('Erro ao salvar dados do usuário: ${userDataResponse.body}');
        }

        final userData = json.decode(userDataResponse.body);

        currentUserId = userId;
        currentUserName = username;
        currentUserEmail = email;
        isAdmin = await checkIfUserIsAdmin(userId);

        await _saveUserData(userId, username, email);

        return {
          ...authData,
          'username': username,
          'userData': userData,
        };
      } catch (e) {
        print('Erro ao salvar dados do usuário: $e');
        return authData;
      }
    } catch (e) {
      print('Erro no cadastro: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    currentUserId = null;
    currentUserName = null;
    currentUserEmail = null;
    isAdmin = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String getErrorMessage(String code) {
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'Este email já está em uso.';
      case 'INVALID_EMAIL':
        return 'Email inválido.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Operação não permitida.';
      case 'WEAK_PASSWORD':
        return 'A senha é muito fraca.';
      case 'EMAIL_NOT_FOUND':
        return 'Email não encontrado.';
      case 'INVALID_PASSWORD':
        return 'Senha incorreta.';
      case 'USER_DISABLED':
        return 'Usuário desativado.';
      default:
        return 'Ocorreu um erro. Tente novamente.';
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential userCredential =
            await _firebaseAuth.signInWithPopup(googleProvider);
        final User? user = userCredential.user;

        if (user != null) {
          return await _processGoogleUser(user);
        }
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential authResult =
            await _firebaseAuth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          return await _processGoogleUser(user);
        }
      }
      return null;
    } catch (e) {
      print('Erro no login com Google: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _processGoogleUser(User user) async {
    try {
      final userDataResponse = await http.get(
        Uri.parse('$dbUrl/users/${user.uid}.json'),
      );

      Map<String, dynamic>? userData;
      if (userDataResponse.body != "null") {
        userData = json.decode(userDataResponse.body);
      }

      if (userData == null) {
        final newUserData = {
          'username': user.displayName ?? 'Usuário Google',
          'email': user.email,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await http.put(
          Uri.parse('$dbUrl/users/${user.uid}.json'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(newUserData),
        );

        userData = newUserData;
      }

      currentUserId = user.uid;
      currentUserName =
          userData['username'] ?? user.displayName ?? 'Usuário Google';
      currentUserEmail = user.email;
      isAdmin = await checkIfUserIsAdmin(user.uid);

      await _saveUserData(
        user.uid,
        currentUserName!,
        user.email ?? '',
      );

      return {
        'localId': user.uid,
        'email': user.email,
        'username': currentUserName,
      };
    } catch (e) {
      print('Erro ao processar dados do usuário: $e');
      throw 'Erro ao processar dados do usuário';
    }
  }
}
