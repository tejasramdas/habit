Julia deps: see Project.toml (activate local environment)
Python deps: pyserial
Need to give access to serial port for PyBoard (`sudo chmod 777 /dev/ttyACM0')

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

1/7/23
1. Para tracking seems to be working. Changed sizes of blobs and frames. Also passing delta frame through threshold.
2. Added path visualization. Change plotting to only get window around current location to make things faster. Arrows probably make it a bit slower than I'd like.
3. Saving first frame from camera (to get initial cam time) rather than burning. Safer in the long run when trying to sync things together.
4. Synced LED with camera but haven't properly output. Added LED log using camera time to CSV but it's incorrect at the moment.

1/8/23
1. I was multiplying camera time by 10e-8 = 1e7 rather than 1e-9. Geez. 
2. LED sync works fine. Log makes final LED status 1 if final timestamp is greater than recording time.
2. Tried recording tracking video. Works well. Need to make function.

3/5/23
1. Updated light stimulus to include projector with Makie
2. Fixed light stimulus loop to only toggle when required, not on every iteration

To do:
1. Simple interface for recording/saving. 
2. Precompile for quick startup
