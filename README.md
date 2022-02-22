# beamlineGUI
## Project Description
A MATLAB program providing a GUI and command-and-control support for the Peabody Scientific ion beamline (in Morse Hall 145).

## How to Use
Using the program is as simple as running the startup.m script, which adds the necessary subfolders to the path and instantiates the GUI via:
```matlab
myGUI = beamlineGUI;
```

The GUI can then be used to perform various functions such as adjusting beamline settings or running test acquisitions, and if needed the GUI can be accessed directly using the `myGUI` handle. 

## How to Contribute
Support for new acquisition types can be added by defining a function with a beamlineGUI handle as the only input argument and no output arguments. The name of the function can then be added to the AcquisitionList property (case and white space insensitive) to allow user selection.
The OperatorList and GasList properties can also be easily expanded to include new selectable options.
