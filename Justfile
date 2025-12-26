set shell := ["bash", "-lc"]

# Run ormed unit tests
test-ormed:
	cd packages/ormed && just test

# Run driver_tests suite
test-driver_tests:
	cd packages/driver_tests && just test

# Run ormed_sqlite unit tests
test-ormed_sqlite:
	cd packages/ormed_sqlite && just test

# Run ormed_cli unit tests
test-ormed_cli:
	cd packages/ormed_cli && just test

# Run ormed_mysql database-backed tests (defaults to running both MySQL & MariaDB suites)
test-ormed_mysql:
	cd packages/ormed_mysql && just test

# Run ormed_postgres database-backed tests
test-ormed_postgres:
	cd packages/ormed_postgres && just test

# Run all unit-test-only packages
test-packages: test-ormed test-ormed_sqlite test-ormed_cli

# Run the bootstrap E2E test
test-bootstrap:
	dart tool/test_bootstrap.dart

# Run all tests, including database-backed suites (requires Docker)
test-all: test-packages test-ormed_postgres test-ormed_mysql
