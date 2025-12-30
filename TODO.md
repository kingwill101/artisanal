- (done) Figure what it would take to wire up similar semantics in ormed
 ```
.where((q) => q.key.eq(key))
          .where((q) => q.owner.eq(owner))
```

where each field has some sort of interface on the Query where we can filter

- generate copyWith for user defined models


- option to run init and only generate what you need. datasourc.dart/migration.dart etc
- init shows Do you want to add missing ormed dependencies to pubspec.yaml? [Y/n] y even when we already added the packages (add test to verify)

- (done) Implement full text search per each driver.
- make it easier to implement certain database operations via 3rd part packages possibly via extensions
