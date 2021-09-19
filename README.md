<!--
SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>

SPDX-License-Identifier: Apache-2.0
-->

# aioc - all in one container
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/opossum-tool/opossumUI/blob/main/LICENSES/Apache-2.0.txt)
[![REUSE status](https://api.reuse.software/badge/git.fsfe.org/reuse/api)](https://api.reuse.software/info/git.fsfe.org/reuse/api)


* **State:** demonstrator / not production ready
* ... needs a better name

## What it does

This docker based pipeline uses 
* the **OSS Review Toolkit**, built from the fork https://github.com/opossum-tool/oss-review-toolkit,
* **ScanCode** (https://github.com/nexB/scancode-toolkit/),
* **OWASP Dependency-Check** (https://owasp.org/www-project-dependency-check/) and
* **SCANOSS** (https://github.com/scanoss/scanner.c)

to scan the provided source directory.
It is able to consume arbitrary source code and tries to do its best, with the limitation that Ort requires the folder to be under version control. 
The results are merged via [opossum.lib.hs](https://github.com/opossum-tool/opossum.lib.hs) to a single `merged-opossum.input.json.gz`.

![README.png](./README.png)

The whole tooling is selfcontained in a single docker image, that consumes the content of `/intput` and produces the ressults in `/output`.

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

