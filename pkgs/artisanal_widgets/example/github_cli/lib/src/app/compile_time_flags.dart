const githubCliNetworkImagesDefine = 'GITHUB_CLI_ENABLE_NETWORK_IMAGES';
const githubCliAutomationCliDefine = 'GITHUB_CLI_ENABLE_AUTOMATION_CLI';
const githubCliReplayCliDefine = 'GITHUB_CLI_ENABLE_REPLAY_CLI';
const githubCliProfileCliDefine = 'GITHUB_CLI_ENABLE_PROFILE_CLI';

const githubCliNetworkImagesEnabled = bool.fromEnvironment(
  githubCliNetworkImagesDefine,
  defaultValue: true,
);

const githubCliAutomationCliEnabled = bool.fromEnvironment(
  githubCliAutomationCliDefine,
);

const githubCliReplayCliEnabled =
    githubCliAutomationCliEnabled ||
    bool.fromEnvironment(githubCliReplayCliDefine);

const githubCliProfileCliEnabled =
    githubCliAutomationCliEnabled ||
    bool.fromEnvironment(githubCliProfileCliDefine);

const githubCliReplayCliDartDefineArgument = '-D$githubCliReplayCliDefine=true';
