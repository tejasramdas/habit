Julia deps: see Project.toml (activate local environment)
Python deps: pyserial

Updates:
1/4/23
1. Fixed saving. Options to save as separate images or as JLD.
2. New processing pipeline file with attempted FFT.
3. Simple python script to toggle LED.
4. Automatically create new folder for each recording. Save frame and camera stats.
5. Added Julia PyCall function for LED. PyCall wraps Python wraps Micropython REPL.

1/6/23
1. Increase FPS. Need to figure out optimzation in Spinnaker.
2. Switched saving to HDF5, preallocating arrays for speed.
3. Refactored `record` function. Removed `get_many_frames`. Continues to run until all the frames up to given time are retrieved (rather than stopping when computer time runs out).
4. Plot tracks after getting para locations (very basic using blobLoG)

To do:
1. Simple interface for recording/saving. 
2. Integrate with PyCall and sync LED.
3. Precompile for quick startup
