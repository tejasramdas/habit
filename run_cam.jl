include("cam.jl")

led=led_init()

led.high()
sleep(1)
led.low()

cam=init_cam(40,10000,"";prop=true);

obs_img=init_img();

fig=init_disp(obs_img);

display(fig)

img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);

# stat=record(cam,60;save_frame=true,disp=false,stat=true);

SAVE_FRAME=[true,false][1]
DISPLAY=[true,false][2]
STROBE=["projector","led","none"][3]
TRIAL_LENGTH=120
PULSE=1
PERIOD=10
notes="Duration: $TRIAL_LENGTH s \nStimulus: $STROBE \nPulse: $PULSE s \nPeriod: $PERIOD s \n\n"
notes*="5 para, no stimulus (for video tracking test)"
print(notes)

# stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes=notes);

f,ax=create_screen()
display(f)

stat=record(cam,TRIAL_LENGTH;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=true,notes=notes,strobe=STROBE,p_w=PULSE,period=PERIOD,led=led,proj_ax=ax);

plot_stats(stat);

# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end
