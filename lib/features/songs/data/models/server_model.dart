class ServerManager {
  int _index = 0;

  final List<AudioServer> servers = [
    AudioServer.server1,
    AudioServer.server2,
    AudioServer.server3,
    AudioServer.server4,
  ];

  AudioServer next() {
    final server = servers[_index];
    _index = (_index + 1) % servers.length;
    return server;
  }
}

enum AudioServer { server1, server2, server3, server4 }
