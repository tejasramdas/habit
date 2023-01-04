Archive:
1. GLMakie needs to be imported twice. Fails to load first time. SOLVED: Load Spinnaker at the end.
2. USB 3 ports don't seem to work as USB 2. SOLVED: Issue with cable, 
3. Memory overload when trying to stream camera using Makie observable. SOLVED: Use raw image array as obserable and set camera buffer to NewestOnly.
4. Updated Spinnaker package has not been installed (release is still misspelled). DUMB
5. Need to get continuous camera mode working. SOLVED
6. Save image function keeps hanging. Sometimes get image also hangs. SOLVED: Saving image on my own, outside loop.
7. Camera frame rate capped at 10 Hz, probably because of power. SOLVED: replaced cable
8. Calling CameraList() a second time messes things up e.g. prevents access to properties. IGNORE
