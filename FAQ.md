## Common Errors ##
Below is a list of reported errors that have come up, and how to fix them.

### The file pthreadGC2.dll is missing or not loaded ###
This ANE depends on the POSIX Threading Library provided by GCC.  This file is extremely common, but may not be present on all copies of Windows.  It is included in this ANE package, but may need to be installed separately.  Either extract the .ANE file (it is located in the /META-INF/ane/Windows-x86 folder), or download a copy from the Downloads tab in the project.  Copy it to the following locations :

  * Windows XP(32/64), Windows Vista(32), Windows 7(32) - C:\Windows\System32\
  * Windows Vista(64), Windows 7(64) - C:\Windows\SysWOW64\

### My AIR Application or ADL.EXE crashes when the app is closing ###
It is a requirement of the AIR Runtime that you call the `dispose()` function before the app ends in order to unload the ANE and all of its allocated resources.  This is extra important with this ANE as it works with file handlers that the OS will need to free up for other applications.

There are instances where the ADL will crash even though the dispose function is called.  This is a known timing issue with AIR 3.

### I get an error stating that the method `setupPort` was not found ###
There is a known issue with Flash Builder 4.6 and Flash Builder 4.7 on the Mac OSX platform.  FB 4.x does not pass the proper command line parameters to ADL in order to include the ANE.

You have three options to fix the issue :
  * Execute your app using the Export Release Build.  This will build the AIR app in a way that will run the project just fine.
  * Run ADL from the command line.  Extract the .ANE to a location you will be familar with, and execute the adl -profile extendedDesktop -extdir <path to extracted ANE> <path to your app descriptor xml>
  * Create an ANT script to launch the debug version of your app. This is what I recommend, but it takes a bit of setup.