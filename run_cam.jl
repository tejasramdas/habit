#Load packages
include("cam.jl")
run(`stty sane`)
#Initialize Raspberry Pi
stim=load_rpi()
#Initialize camera and display
cam=init_cam(10,10000,"";prop=true);
obs_img=init_img();
time_start=Observable(0)
stim_on=Observable(false)
start_toggle=Observable(false)
start_exp=Observable(false)

TRIAL_LENGTH =Observable(3600.0) 
ITI =Observable(3600.0)
PULSE =Observable(0.05)
PERIOD =Observable(60.0)
STIM_OFFSET =Observable(2.0)
STIM_VOLTAGE =Observable(7.0)
DELAY =Observable(0.0)
NOTES=Observable("Forgot to enter notes!")
LIGHT_LEVEL=Observable(10.0)
ABORT=Observable(false)



fig=Figure()
figa = fig[1, 1] = GridLayout(height=512,width=512)
figb = fig[1, 2] = GridLayout(height=512,width=128)
figc = fig[1, 3] = GridLayout(hieght=512, width=384)
colgap!(fig.layout, 32)
#=colgap!(figb, 10)=#
#=rowgap!(figb, 10)=#
#=colsize!(figb.layout, 1, Auto(0.5))=#
#=colsize!(figc.layout, 1, Auto(0.5))=#
#=figa_box=Box(figa[1,1:2], color = (:blue, 0.1), strokecolor = :transparent)=#
figb_box=Box(figb[0:13,0:2], color = (:blue, 0.1), strokecolor = :transparent)
figc_box=Box(figc[0:3,0:2], color = (:black, 0.1), strokecolor = :transparent)
ax=GLMakie.Axis(figa[1,1], aspect=DataAspect(), spinewidth = 3, topspinecolor = @lift($stim_on ? "red" : "black"), leftspinecolor = @lift($stim_on ? "red" : "black"), rightspinecolor = @lift($stim_on ? "red" : "black"), bottomspinecolor = @lift($stim_on ? "red" : "black"),width=512)
image!(ax, obs_img,colorrange=(0,256))
hidedecorations!(ax)
toggles = [Toggle(fig, active = active) for active in [true, false, false, false]]
labels = [Label(fig, l) for l in ["Display video", "Save video", "Stimulus", "LED"]]
figb[1, 1] = grid!(hcat(toggles, labels), tellheight = true)
# colsize!(figa.layout, 1, Aspect(1,1.0))
start =  Button(fig, label = @lift(($start_exp ? "Stop" : "Start")*" experiment"))
exp_stat = Label(fig,  @lift($start_exp ? ($start_toggle ? "Running trial" : "Waiting") : "Experiment off" ))
curr_exp_t = Label(fig,  @lift(lpad("$(Int(floor($time_start/60)))",2, "0")*":"*lpad("$($time_start%60)",2, "0")))
#=settings = figa[9, 11] = Button(fig, label = "Adjust settings")=#
figb[5, 1] = grid!(reshape([start,exp_stat,curr_exp_t],(3,1)), tellheight = true)
abort = figb[10, 1] = Button(fig, label = "ABORT", buttoncolor=:red, labelcolor=:white, strokewidth=3, strokecolor=:black)
textboxes = [Textbox(fig, placeholder = @lift("$($obs)"),width=100,validator=Float64) for obs in [TRIAL_LENGTH, ITI, PULSE, PERIOD, DELAY, LIGHT_LEVEL]]
labels2 = [Label(fig, l) for l in ["Trial length (s)","ITI (s)","Pulse (s)","Period (s)","Delay (s)", "Light level (0-255)"]]
labels3 = [Label(fig, @lift("$($l)"),width=50) for l in [TRIAL_LENGTH, ITI, PULSE, PERIOD, DELAY, LIGHT_LEVEL]]
warn = Label(fig, "Make sure to hit enter! \n(Textboxes should be bold)")
adjust =  Button(fig, label = @lift($start_exp ? "Disabled" : "Save settings"))
figc[1, 1] = grid!(hcat(labels2, textboxes, labels3), tellheight = true)
figc[2, 1] = grid!(reshape([warn,adjust],(2,1)), tellheight = true)
resize!(fig, 512+128+512+64, 548) 
display(fig)
img=get_one_frame(cam,obs_img);
println("READY");
#Settings for experiment
PRINT_STAT=[true,false][1]
DISPLAY=@lift(Bool($(toggles[1].active)))
SAVE_FRAME=@lift(Bool($(toggles[2].active)))
STROBE=@lift(Bool($(toggles[3].active)))
LED=@lift(Bool($(toggles[4].active)))

empty!(adjust.clicks.listeners)
empty!(abort.clicks.listeners)
empty!(start.clicks.listeners)
on(adjust.clicks) do n
    if !start_exp[]
        for (i,j) in enumerate([TRIAL_LENGTH,ITI,PULSE,PERIOD,DELAY,LIGHT_LEVEL])
            if textboxes[i].stored_string[] != nothing
                j[]=parse(Float64, textboxes[i].stored_string[])
            end
        end
        sleep(0.5)
        NOTES[]="Trial duration: $(TRIAL_LENGTH[]) s\nITI: $(ITI[]) s\nPulse: $(PULSE[]) s \nPeriod: $(PERIOD[]) s \nDelay before start: $(DELAY[]) s \nStim voltage: $(STIM_VOLTAGE[])\nOffset: $(STIM_OFFSET[]) s\nLight level: $(LIGHT_LEVEL[])" 
    end
end
on(abort.clicks) do n
    ABORT[]=true
end
on(start.clicks) do n
    start_exp[]=1-start_exp[]
end
on(LED) do n
    lev=Int(floor(LIGHT_LEVEL[]*LED[]))
    stim.set_led(lev,lev,lev)
end
on(LIGHT_LEVEL) do n
    lev=Int(floor(LIGHT_LEVEL[]*LED[]))
    stim.set_led(lev,lev,lev)
end


ABORT[]=false
display(fig)
stat=record_inf(cam;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=PRINT_STAT,strobe=STROBE,p_w=PULSE,period=PERIOD,stim=stim,stim_on=stim_on,stim_offset=STIM_OFFSET,start_toggle=start_toggle,t_start=time_start,start_exp=start_exp,led=LED,TRIAL_LENGTH=TRIAL_LENGTH,ITI=ITI,NOTES=NOTES,DELAY=DELAY);

