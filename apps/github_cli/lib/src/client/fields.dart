const ghRepositoryFields = <String>[
  'nameWithOwner',
  'description',
  'url',
  'defaultBranchRef',
  'stargazerCount',
  'forkCount',
  'isPrivate',
  'viewerPermission',
  'primaryLanguage',
  'latestRelease',
];

const ghIssueFields = <String>[
  'number',
  'title',
  'body',
  'url',
  'author',
  'labels',
  'comments',
  'updatedAt',
  'assignees',
];

const ghPullRequestFields = <String>[
  'number',
  'title',
  'body',
  'url',
  'author',
  'headRefOid',
  'additions',
  'deletions',
  'changedFiles',
  'commits',
  'labels',
  'comments',
  'updatedAt',
  'reviewDecision',
  'statusCheckRollup',
  'isDraft',
];

const ghPullRequestMergeFields = <String>[
  'number',
  'title',
  'state',
  'isDraft',
  'mergeable',
  'reviewDecision',
  'autoMergeRequest',
  'statusCheckRollup',
];

const ghWorkflowFields = <String>['id', 'name', 'path', 'state'];

const ghWorkflowRunFields = <String>[
  'databaseId',
  'number',
  'attempt',
  'workflowName',
  'displayTitle',
  'status',
  'conclusion',
  'event',
  'headBranch',
  'url',
  'createdAt',
  'updatedAt',
];
