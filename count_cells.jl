using ImageView, JLD, Gtk4#, Gtk.ShortNames

println("Enter file name:")
file_loc=readline()


file_loc="tiled"

tiled_arr=load("$file_loc.jld")["frames"]

guidict=imshow(tiled_arr)


frame_num=Observable[1]


fig=Figure()
ax=Axis(f[:,:])
img_plot=image!(ax,@lift(tiled_arr[:,:,frame_num]),interpolate=false)


if (!isinteractive())

    # Create a condition object
    c = Condition()

    # Get the window
    win = guidict["gui"]["window"]
    
    # Start the GLib main loop
    @async Gtk4.GLib.glib_main()

    # Notify the condition object when the window closes
    signal_connect(win, :close_request) do widget
        notify(c)
    end

    # Wait for the notification before proceeding ...
    wait(c)
end

