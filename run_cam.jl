include("cam.jl")
include("led.jl")

led=led_init()

led.high()
led.low()

cam=init_cam(40,10000,"";prop=true);

# obs_img=init_img();

# fig=init_disp(obs_img);


img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);

# stat=record(cam,5;save_frame=true,disp=false,stat=true);

SAVE_FRAME=true
notes="5 para led flash"

# stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes=notes);

# stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes=notes,led_strobe=true,p_w=0.2,period=1,led=led);

# plot_stats(stat);

# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end
