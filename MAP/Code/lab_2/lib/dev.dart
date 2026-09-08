abstract interface class Workable {
  String getWorkStatus();
}

abstract class DeveloperRole {
  String? title;
  final double experienceYears;
  DeveloperRole(this.title, this.experienceYears);
  void performTask();
}

class SystemInfrastructure {
  final String? environment;
  SystemInfrastructure(this.environment);
  void checkStatus() => print("System environment is currently $environment");
}

class FrontendDeveloper extends DeveloperRole
    implements Workable, SystemInfrastructure {
  final String framework;

  @override
  String? get environment => "Client Side";

  FrontendDeveloper(double experienceYears, this.framework)
    : super("Frontend Developer", experienceYears);
  FrontendDeveloper.senior() : this(8.0, "React");

  @override
  String getWorkStatus() => "Building user interface components";

  @override
  void checkStatus() =>
      print("Frontend environment is stable at the level of $environment");

  @override
  void performTask() => print("Coding UI with $framework framework");
}

class BackendDeveloper extends DeveloperRole
    implements Workable, SystemInfrastructure {
  double? _serverLoad;

  BackendDeveloper(double experienceYears, this._serverLoad)
    : super("Backend Developer", experienceYears);
  BackendDeveloper.junior() : this(1.0, 0.2);

  @override
  String? get environment => "Server/Cloud Infrastructure";

  double? get serverLoad => _serverLoad;

  set serverLoad(double? value) {
    if (value == null || value < 0) {
      throw Exception("Server load value must not be null or negative");
    }
    _serverLoad = value;
  }

  @override
  String getWorkStatus() => "Managing databases and API endpoints";

  @override
  void checkStatus() =>
      print("Backend infrastructure load is currently: $serverLoad");

  @override
  void performTask() =>
      print("Processing server-side logic. Current load: $_serverLoad units");
}

void manageWorkflow(DeveloperRole role, {bool log = true, int cycles = 1}) {
  if (log) {
    print("${role.title} is beginning a sprint");
  }
  for (int i = 0; i < cycles; i++) {
    role.performTask();
  }
}

void main() {
  try {
    List<DeveloperRole> engineeringTeam = [
      FrontendDeveloper(3.0, "Vue"),
      FrontendDeveloper(2.5, "Angular"),
      BackendDeveloper(5.0, 0.45),
      BackendDeveloper.junior(),
      FrontendDeveloper.senior(),
      BackendDeveloper(4.0, 0.7),
      BackendDeveloper(6.5, 0.55),
    ];

    Set<String> stackTechnologies = {"Dart", "JavaScript", "Python"};

    Map<int, String> releaseScheduleMap = {
      9: "Daily Stand-up",
      11: "Feature Development",
      14: "Code Review",
      16: "Bug Fixing",
      18: "Deployment",
    };

    print("Engineering stack: $stackTechnologies");

    print("\nRelease Schedule from Map:");
    releaseScheduleMap.forEach((time, activity) {
      print("At $time:00 the team activity is $activity");
    });

    print("\nTeam workflow modelling:");
    for (var dev in engineeringTeam) {
      if (dev is BackendDeveloper && dev.serverLoad! > 0.9) {
        print("CRITICAL: Server crash imminent!");
        break;
      }
      if (dev.experienceYears < 2.0 && dev is! FrontendDeveloper) {
        continue;
      }
      manageWorkflow(dev, cycles: 2);
    }

    print("\nTesting errors:");
    var backend = BackendDeveloper(2.0, 0.5);
    backend.serverLoad = -1.0;
  } on Exception catch (e) {
    print("Developer workflow error: $e");
  } catch (e) {
    print("General system error: $e");
  } finally {
    print("Development cycle ends");
  }
}
