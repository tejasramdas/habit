include("cam.jl")

led=led_init()

led.high()
sleep(1)
led.low()

cam=init_cam(20,10000,"";prop=true);

obs_img=init_img();

# fig=init_disp(obs_img);

# display(fig)

# img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);

# stat=record(cam,60;save_frame=true,disp=false,stat=true);

SAVE_FRAME=[true,false][2]
DISPLAY=[true,false][2]
STROBE=["projector","led"][1]
notes="testing 40s with 15 Hz 1s led @ 20 FPS"

# stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes=notes);

f,ax=create_screen()

stat=record(cam,40;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=true,notes=notes,strobe=STROBE,p_w=1,period=4,led=led,proj_ax=Nothing);

plot_stats(stat);

# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end
