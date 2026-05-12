import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fdjogjwmigdndvtqyyix.supabase.co',
  );
  const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_tA-yJyIQZPOhAv1gera6Lg_-av6UwmZ',
  );
  final bool hasSupabaseConfig =
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty && !supabaseAnonKey.contains('SUA_');

  if (hasSupabaseConfig) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(MyApp(supabaseReady: hasSupabaseConfig));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    if (!supabaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRUD Supabase',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F7A8C),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const SetupPage(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD Supabase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F7A8C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final authState = snapshot.data;
          final session = authState?.session;

          if (session != null) {
            return const UsersPage();
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha email e senha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          setState(() {
            _errorMessage = 'Conta criada! Verifique seu email para confirmar.';
            _isSignUp = false;
            _passwordController.clear();
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primaryContainer.withOpacity(0.35),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          _isSignUp ? 'Criar Conta' : 'Login',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 12),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _isSignUp && _errorMessage!.contains('Conta criada')
                                    ? colorScheme.primary
                                    : colorScheme.error,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        FilledButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isSignUp ? 'Criar Conta' : 'Entrar'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _errorMessage = null;
                                    _passwordController.clear();
                                  });
                                },
                          child: Text(
                            _isSignUp
                                ? 'Já tem conta? Entrar'
                                : 'Não tem conta? Criar nova',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _usersFuture;
  bool _isSubmitting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await _supabase.from('users').select('id, name, email');
      return response
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _addUser() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      setState(() {
        _statusMessage = 'Preencha nome e email para salvar.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      await _supabase.from('users').insert(<String, String>{
        'name': name,
        'email': email,
      });

      _nameController.clear();
      _emailController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Usuário salvo com sucesso.';
      });

      await _refreshUsers();
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Erro ao salvar usuário: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _updateUser({
    required dynamic id,
    required String name,
    required String email,
  }) async {
    final String trimmedName = name.trim();
    final String trimmedEmail = email.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
      setState(() {
        _statusMessage = 'Preencha nome e email para editar.';
      });
      return;
    }

    setState(() {
      _statusMessage = null;
    });

    try {
      await _supabase.from('users').update(<String, String>{
        'name': trimmedName,
        'email': trimmedEmail,
      }).eq('id', id);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Usuário atualizado com sucesso.';
      });

      await _refreshUsers();
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Erro ao atualizar usuário: $error';
      });
    }
  }

  Future<void> _deleteUser(dynamic id) async {
    setState(() {
      _statusMessage = null;
    });

    try {
      await _supabase.from('users').delete().eq('id', id);

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Usuário removido com sucesso.';
      });

      await _refreshUsers();
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Erro ao remover usuário: $error';
      });
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final dynamic id = user['id'];
    final TextEditingController editNameController =
        TextEditingController(text: user['name'] as String? ?? '');
    final TextEditingController editEmailController =
        TextEditingController(text: user['email'] as String? ?? '');

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Editar usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true && id != null) {
      await _updateUser(
        id: id,
        name: editNameController.text,
        email: editEmailController.text,
      );
    }

    editNameController.dispose();
    editEmailController.dispose();
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final dynamic id = user['id'];
    if (id == null) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Excluir usuário'),
          content: const Text(
            'Tem certeza que deseja excluir este usuário?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteUser(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.primaryContainer.withOpacity(0.35),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Olá, ${user?.email ?? 'Usuário'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sair'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: colorScheme.surface.withOpacity(0.88),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Flutter + Supabase',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'CRUD simples para listar e inserir registros na tabela users.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                FilledButton.icon(
                                  onPressed: _isSubmitting ? null : _addUser,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    _isSubmitting ? 'Salvando...' : 'Salvar',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _refreshUsers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Atualizar lista'),
                                ),
                              ],
                            ),
                            if (_statusMessage != null) ...<Widget>[
                              const SizedBox(height: 12),
                              Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _usersFuture,
                            builder: (BuildContext context,
                                AsyncSnapshot<List<Map<String, dynamic>>>
                                    snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Erro ao carregar usuários: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              final List<Map<String, dynamic>> users =
                                  snapshot.data ?? <Map<String, dynamic>>[];

                              if (users.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Nenhum usuário encontrado ainda.',
                                  ),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: _refreshUsers,
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: users.length,
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                    return const Divider(height: 1);
                                  },
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final Map<String, dynamic> user =
                                        users[index];
                                    final String name =
                                        (user['name'] as String? ?? '').trim();

                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name.substring(0, 1).toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      title: Text(name),
                                      subtitle:
                                          Text(user['email'] as String? ?? ''),
                                      trailing: Wrap(
                                        spacing: 4,
                                        children: <Widget>[
                                          IconButton(
                                            onPressed: () {
                                              _showEditDialog(user);
                                            },
                                            tooltip: 'Editar',
                                            icon: const Icon(Icons.edit),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _confirmDeleteUser(user);
                                            },
                                            tooltip: 'Excluir',
                                            icon: const Icon(Icons.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Supabase ainda não configurado',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Passe as variáveis SUPABASE_URL e SUPABASE_ANON_KEY ao executar o app para carregar a tela de CRUD.',
                    ),
                    const SizedBox(height: 16),
                    const Text('Exemplo:'),
                    const SizedBox(height: 8),
                    SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=https://SUA_URL.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'O build continua funcionando sem as chaves, mas a leitura e inserção de dados ficam desativadas até a configuração correta.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
