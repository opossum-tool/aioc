<!--
SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>

SPDX-License-Identifier: Apache-2.0
-->

# aioc - all in one container
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/opossum-tool/opossumUI/blob/main/LICENSES/Apache-2.0.txt)
[![REUSE status](https://api.reuse.software/badge/git.fsfe.org/reuse/api)](https://api.reuse.software/info/git.fsfe.org/reuse/api)

... needs a better name

* **State:** demonstrator / not production ready

## What it does

![README.png](./README.png)

## How to run:

Build the docker image (once):
``` sh
$ ./build-docker-image.sh
```

Scan the root of a project (fo ORT, it must be under vcs):
``` sh
$ ./run-on-folder.sh path/to/project/root
```
this generates a folder `path/to/project/root_aioc` containing the file `merged-opossum.input.json.gz`.

