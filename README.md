PCKeyboard 2
============

Application-targetted emulation of "PC-Style" Delete and End.


Introduction
------------

PCKeyboard is a module to change the use of the Delete, End (Copy) and Home keys in applications under RISC OS.  Historically, the Delete key on RISC OS has always duplicated Backspace, which is different from the behaviour on other platforms.  On RISC OS 5 this behaviour is changed to the "PC style" and the OS tries to enforce this, but not all applications follow suit.

The module can be used in three ways:

* It can be used on RISC OS 5 to convert applications fixed in "Acorn style" operation over to the "PC style" used by the OS.

* Alternatively, on RISC OS 5, it can be used to convert the behaviour of writable icons, and any applications which detect the OS and insist on "PC style" operation, back to "Acorn style" usage.

* On all other versions of RISC OS, it can be used to convert the behaviour of applications and writable icons to "PC style" operation.

PCKeyboard 1 worked at a low level in RISC OS, changing the codes returned from the keyboard.  This ensured that the changes took effect in all parts of the OS, but it could also conflict with third-party keyboard extenders.

With the arrival of RISC OS 5, where the Wimp and bundled applications already use the "PC style" actions by default, PCKeyboard 2 has been written to work on an application by application basis by applying Wimp filters.  This allows it to only work on those applications which need to be modified and, because it can work at a much higher level in the OS, many of the old conflicts have been resolved.

Where possible, I recommend updating applications to correct their use of Delete instead of adding them to the list in  PCKeyboard.  Many RISC OS applications (such as Zap and Pipedream) can have their key bindings changed by editing a file contained in the application; many others have a simple "PC Delete" option in their configuration.  If possible, this is a better solution than filtering them with this module.


Building
--------

PCKeyboard 2 consists of a collection of ARM assembler and un-tokenised BASIC, which must be assembled using the [SFTools build environment](https://github.com/steve-fryatt). It will be necessary to have suitable Linux system with a working installation of the [GCCSDK](http://www.riscos.info/index.php/GCCSDK) to be able to make use of this.

With a suitable build environment set up, making PCKeyboard 2 is a matter of running

	make

from the root folder of the project. This will build everything from source, and assemble a working PCKeyboard 2 module and its associated files within the build folder. If you have access to this folder from RISC OS (either via HostFS, LanManFS, NFS, Sunfish or similar), it will be possible to run it directly once built.

To clean out all of the build files, use

	make clean

To make a release version and package it into Zip files for distribution, use

	make release

This will clean the project and re-build it all, then create a distribution archive (no source), source archive and RiscPkg package in the folder within which the project folder is located. By default the output of `git describe` is used to version the build, but a specific version can be applied by setting the `VERSION` variable -- for example

	make release VERSION=1.23


Licence
-------

PCKeyboard 2 is licensed under the EUPL, Version 1.2 only (the "Licence"); you may not use this work except in compliance with the Licence.

You may obtain a copy of the Licence at <http://joinup.ec.europa.eu/software/page/eupl>.

Unless required by applicable law or agreed to in writing, software distributed under the Licence is distributed on an "**as is**"; basis, **without warranties or conditions of any kind**, either express or implied.

See the Licence for the specific language governing permissions and limitations under the Licence.