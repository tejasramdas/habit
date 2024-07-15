#Load packages
using ImageView
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

fig=Figure()
ax=GLMakie.Axis(fig[1:10,1:10], aspect=DataAspect(), spinewidth = 3, topspinecolor = @lift($stim_on ? "red" : "black"), leftspinecolor = @lift($stim_on ? "red" : "black"), rightspinecolor = @lift($stim_on ? "red" : "black"), bottomspinecolor = @lift($stim_on ? "red" : "black"))
image!(ax, obs_img,colorrange=(0,256))
hidedecorations!(ax)
# resize!(fig, 512, 512) 
toggles = [Toggle(fig, active = active) for active in [true, false, false, false]]
labels = [Label(fig, l) for l in ["Display video", "Save video", "Stimulus", "LED"]]
fig[1:5, 11] = grid!(hcat(toggles, labels), tellheight = false)
# colsize!(fig.layout, 1, Aspect(1,1.0))
start = fig[6, 11] = Button(fig, label = @lift(($start_exp ? "Stop" : "Start")*" experiment"))
fig[8, 11] = Label(fig,  @lift($start_exp ? ($start_toggle ? "Running trial" : "Waiting") : "Experiment off" ))
fig[9, 11] = Label(fig,  @lift(lpad("$(Int(floor($time_start/60)))",2, "0")*":"*lpad("$($time_start%60)",2, "0")))
display(fig)
img=get_one_frame(cam,obs_img);
println("READY");
#Settings for experiment
PRINT_STAT=[true,false][1]
DISPLAY=@lift(Bool($(toggles[1].active)))
SAVE_FRAME=@lift(Bool($(toggles[2].active)))
STROBE=@lift(Bool($(toggles[3].active)))
LED=@lift(Bool($(toggles[4].active)))

LIGHT_LEVEL=Observable(10)
stim.set_led(LIGHT_LEVEL[],LIGHT_LEVEL[],LIGHT_LEVEL[])
img=get_one_frame(cam,obs_img);


#ORIGINAL METHOD
#=try_num=1=#
#=trial_note="Testing with solenoids"=#
#=println("Starting $trial_note")=#
#=notes*=trial_note=#
#=stat=record(cam,TRIAL_LENGTH;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=PRINT_STAT,notes=notes,strobe=STROBE,p_w=PULSE,period=PERIOD,stim=stim,stim_offset=STIM_OFFSET);=#
#=GC.gc()=#
#=sleep(3600);=#
#=stat=record(cam,TRIAL_LENGTH;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=PRINT_STAT,notes=notes,strobe=STROBE,p_w=PULSE,period=PERIOD,stim=stim,stim_offset=STIM_OFFSET);=#
#==#



on(start.clicks) do n
    start_exp[]=1-start_exp[]
end

on(LED) do n
    stim.set_led(LIGHT_LEVEL[]*LED[],LIGHT_LEVEL[]*LED[],LIGHT_LEVEL[]*LED[])
end
on(LIGHT_LEVEL) do n
    stim.set_led(LIGHT_LEVEL[]*LED[],LIGHT_LEVEL[]*LED[],LIGHT_LEVEL[]*LED[])
end


#=empty!(start.clicks.listeners)=#
#==#
#=empty!(LED.listeners)=#
#=empty!(LIGHT_LEVEL.listeners)=#

println("Enter trial length in seconds (usually 3600):")
TRIAL_LENGTH=parse(Int,readline())
println()
println("Enter ITI in seconds (usually 3600):")
ITI=parse(Int,readline())
println()
println("Enter stimulus pulse duration in seconds (usually 0.05):")
PULSE=parse(Float64,readline())
println()
println("Enter stimulus period in seconds (usually 60):")
PERIOD=parse(Int,readline())
println()
println("Enter stimulus offset in seconds (usually 2):")
STIM_OFFSET=parse(Int,readline())
println()
println("Enter stimulus voltage:")
STIM_VOLTAGE=parse(Int,readline())
println()
println("Enter light level from 0 to 255 (usually 10):")
LIGHT_LEVEL[]=parse(Int,readline())

#=TRIAL_LENGTH = 3600 =#
#=ITI = 3600=#
#=PULSE = 0.05=#
#=PERIOD = 60=#
#=STIM_OFFSET = 2=#
#=STIM_VOLTAGE = 7.0=#
#=LIGHT_LEVEL[] = 10=#

notes="Trial duration: $TRIAL_LENGTH s\nITI: $ITI s\nPulse: $PULSE s \nPeriod: $PERIOD s \nStim voltage: $STIM_VOLTAGE\nOffset: $STIM_OFFSET s\nLight level: $(LIGHT_LEVEL[])"
println()
println(notes)

#==#
#=plot_stats(stat);=#

stat=record_inf(cam;obs_img=obs_img,save_frame=SAVE_FRAME,disp=DISPLAY,stat=PRINT_STAT,strobe=STROBE,p_w=PULSE,period=PERIOD,stim=stim,stim_on=stim_on,stim_offset=STIM_OFFSET,start_toggle=start_toggle,t_start=time_start,start_exp=start_exp,led=LED,TRIAL_LENGTH=TRIAL_LENGTH,ITI=ITI,notes=notes);

