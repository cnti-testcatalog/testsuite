## Ephemeral Development Environment

The Ephemeral Developement Environment is a developer environment that allows the user to contribute to the cnf-testsuite project without having crystall lang installed on the developer's host machine. The enviroment consists of a docker container which has the correct version of crystal lang for cnf-testsuite development installed.

The enviroment is designed to be seamless and invisible to the developer. It takes the regular crystal commands and passes them into the docker environment. It also has intelligent integration with the cnf-testsuite binary.

## Quickstart

Prereqs: [Kind Install](../../KIND-INSTALL.md)

1. Obtain the ephemeral binary

- Download the binary from https://github.com/cnti-testcatalog/testsuite/releases
- OPTIONAL: build the binary yourself using crystal

```
crystal build tools/ephemeral_env/ephemeral_env.cr
```

- OPTIONAL: build the cnf-testsuite binary with static build (to avoid shared object file errors)

```
crystal build src/cnf-testsuite.cr --release --static --link-flags "-lxml2 -llzma"
```

2. Setup the environment based on your binary

```
./ephemeral_env setup -b ./ephemeral_env
```

- OPTIONAL: Use the host's crystal binary

```
crystal tools/ephemeral_env/ephemeral_env.cr -- setup -c /usr/bin/crystal --source tools/ephemeral_env/ephemeral_env.cr
```

3. Add the aliases (check setup output)
   Example:

```
 alias crystal='/usr/bin/crystal tools/ephemeral_env/ephemeral_env.cr command alias -- $@'
 alias cnf-testsuite='/usr/bin/crystal tools/ephemeral_env/ephemeral_env.cr command alias binary -- $@'
```

- OPTIONAL: to restart the setup process, unalias first

```
unalias crystal
unalias cnf-testsuite
```

4.  List the enviroments

```
./ephemeral_env list_envs
```

5. Create an environment

```
./ephemeral_env create_env -n <YOURNEWENVNAME> -k <PATHTOYOURKUBECONFIG.CONF>
```

6. Choose an enviroment

```
export CRYSTAL_DEV_ENV=<ENVNAMEFROMSTEP4ORSTEP5>
```

7. OPTIONAL: Install a sample cnf and run a series of tests

```
crystal src/cnf-testsuite.cr sample_coredns_setup
crystal src/cnf-testsuite.cr installability verbose
```

## Extended Usage

### Environment variables
