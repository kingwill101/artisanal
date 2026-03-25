import 'package:artisanal/artisanal.dart';

class Process {
  final String id;
  final String name;
  final String cpu;
  final String memory;

  Process(this.id, this.name, this.cpu, this.memory);
}

void main() async {
  final io = Console();

  final processes = [
    Process('1024', 'node server.js', '12.5%', '156MB'),
    Process('2048', 'dart run example', '5.2%', '89MB'),
    Process('3072', 'postgres', '1.1%', '512MB'),
    Process('4096', 'redis-server', '0.5%', '32MB'),
    Process('5120', 'chrome --headless', '25.0%', '1.2GB'),
    Process('6144', 'docker-proxy', '0.2%', '12MB'),
    Process('7168', 'flutter run', '18.4%', '450MB'),
    Process('8192', 'code-server', '3.5%', '280MB'),
    Process('9216', 'nginx', '0.1%', '8MB'),
    Process('10240', 'slack', '8.9%', '800MB'),
    Process('11264', 'spotify', '2.3%', '200MB'),
    Process('12288', 'terminal', '0.4%', '45MB'),
  ];

  final selected = await io.dataTable<Process>(
    'Active Processes',
    pageSize: 5,
    columns: [
      Column(title: 'PID', width: 6),
      Column(title: 'Name', width: 20),
      Column(title: 'CPU', width: 8),
      Column(title: 'Mem', width: 10),
    ],
    items: processes,
    rowBuilder: (p) => [p.id, p.name, p.cpu, p.memory],
  );

  if (selected != null) {
    io.success('You selected process: ${selected.name} (${selected.id})');
  } else {
    io.warn('No process selected.');
  }
}
