include("cam.jl")

stim=stim_init()

stim.high()
sleep(0.05)
stim.low()

cam=init_cam(10,10000,"";prop=true);

obs_img=init_img();

fig=init_disp(obs_img);
display(fig)
img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);

# stat=record(cam,60;save_frame=true,disp=false,stat=true);

SAVE_FRAME=[true,false][2]
DISPLAY=[true,false][2]
STROBE=[true,false][1]
PRINT_STAT=[true,false][1]
TRIAL_LENGTH=1800
PULSE=0.02
PERIOD=60
BUZZER_VOLTAGE=8.00
notes="Duration: $TRIAL_LENGTH s\nDisplay: $DISPLAY \nSave: $SAVE_FRAME \nStimulus: $STROBE \nPulse: $PULSE s \nPeriod: $PERIOD s \nBuzzer voltage: $BUZZER_VOLTAGE\n\n"
notes*="Habituation trial with new buzzer setup (double weigh boat). First habituation trial with all this new code. Only 3 anchored cells though.\n"
print(notes)

stat=record(cam,TRIAL_LENGTH;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=PRINT_STAT,notes=notes,strobe=STROBE,p_w=PULSE,period=PERIOD,stim=stim);

stop!(cam)

plot_stats(stat);

# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end


