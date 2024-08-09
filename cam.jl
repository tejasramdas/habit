using GLMakie, Images, ThreadPools, ProgressBars, Dates, CSV, DataFrames, JLD, PyCall, HDF5, JSON, Mmap, VideoIO, ProgressMeter, Spinnaker #load Spinnaker last
# NOTES
# image timestamp units: 1 ns = 10e-6 ms

include("stim.jl")
include("proc.jl")

folder_format="yyyy_mm_dd_HH_MM_SS"
function init_cam(framerate=40,exposure=10000,mode="old";prop=false)
    cam=CameraList()[0];
    framerate!(cam,framerate)
    exposure!(cam,exposure)[1] #microseconds
    triggersource!(cam, "Software")
    triggermode!(cam, "Off")
    acquisitionmode!(cam, "Continuous")
    if mode=="new"
        buffer=buffermode!(cam, "NewestOnly")
    else
        buffermode!(cam, "OldestFirst")
        buffercount!(cam, 45) # max=45
    end
    if prop
        println(JSON.json(cam_prop(cam),4))
    end
    return cam
end

function cam_prop(cam)
    cam_props=Dict{String,Any}("model"=> "$cam", 
    "exposure"=> round(exposure(cam)[1]/1000,digits=2),
    "framerate"=> framerate(cam),
    "trigger"=> triggermode(cam),
    "buffer_mode"=> buffermode(cam),
    "buffer_count"=> buffercount(cam)[1] 
    )
    return cam_props
end

function init_disp(obs_img)
    f=Figure()
    ax=GLMakie.Axis(f[1,1])
    hidedecorations!(ax)
    resize!(f, 512, 512) 
    Threads.@spawn image!(ax,obs_img)
    return f
end

function init_img()
    img=rand(UInt8,512,512)
    obs_img=Observable(img)
    return obs_img
end

function get_one_frame(cam,obs_img;sleept=0,save=false)
    start!(cam);
    sleep(sleept)
    if save
        saveimage(cam,"test",spinImageFileFormat(5));
    else
        img=getimage(cam,Gray{N0f8});
        obs_img[]=UInt8.(floor.(img*255))[1:4:end,end:-4:1];
    end
    stop!(cam);
    return img
end

function print_fps(i, fps, img_ts;stop=false,stim="OFF")
    if stop
        print_stat(i, "Stopped Cam", "$(round(1/(fps[end]-fps[end-1]),digits=1)) FPS Grab","$(round(fps[end]-fps[1],digits=3)) s", stim) 
    else
        print_stat(i, "$(round(10e8/(img_ts[end]-img_ts[end-1]),digits=1)) FPS Cam", "$(round(1/(fps[end]-fps[end-1]),digits=1)) FPS Grab","$(round(fps[end]-fps[1],digits=3)) s", stim)
    end
end

function plot_stats(stats)
    fig=Figure()
    ax1=GLMakie.Axis((fig[1,1]))
    ax2=GLMakie.Axis((fig[1,2]))
    fst=lines!(ax1,collect(0:length(stat[1])-1),(stat[1].-stat[1][1]),label="Frame save time")
    fgt=lines!(ax1,collect(0:length(stat[3])-1),(stat[3].-stat[3][1]), label ="Frame grab time")
    afps=lines!(ax2,collect(0:length(stat[1])-2),diff(stat[1]),label="Acquisition FPS")
    gfps=lines!(ax2,collect(0:length(stat[3])-2),diff(stat[3]), label ="Grab FPS")
    buffercheck=2*(diff(stat[1]).>diff(stat[3])).-1
    buffercount=[0]
    for i in buffercheck
        push!(buffercount,min(45,max(0,buffercount[end]+i)))
    end
    buf=lines!(ax2,collect(0:length(stat[1])-1),buffercount/45, label="Estimated buffer")
    
    Legend(fig[2, :],
    [fst,fgt,afps,gfps,buf],
    ["Frame save time", "Frame grab time", "Acquisition FPS","Grab FPS", "Estimated buffer"])
    disp(fig,x=1000)
end
#==#
#=function record(cam,t=0;stat=false,obs_img=Nothing,disp=false,save_frame=false,fold_name="/home/para/data/"*Dates.format(now(),folder_format),sleept=0.0001,sep=false,notes="",strobe=false,period=2,p_w=1,stim=nothing,stim_offset=0,start_toggle=Observable(true))=#
#=    cam_fps=Int(floor(framerate(cam)))=#
#=    stim_state=false=#
#=    if save_frame=#
#=        mkpath(fold_name)=#
#=        file=open("$fold_name/dat.bin","w+")=#
#=    end=#
#=    beg_ts=0=#
#=    img=zeros(Gray{N0f8},2048,2048)=#
#=    n=1=#
#=    led_arr=[0]=#
#=    start!(cam);=#
#=    img_id,ts_init,_=getimage!(cam,img)=#
#=    start_t=time()=#
#=    fps=[start_t]=#
#=    img_ts=ts_init=#
#=    ts_arr=[ts_init]=#
#=    id_arr=[img_id]=#
#=    img_arr=zeros(UInt8,2048,2048,cam_fps)=#
#=    img_arr[:,:,1].=reinterpret(UInt8,img)=#
#=    stim_on_arr=[]=#
#=    stim_off_arr=[]=#
#=    stim_state="OFF"=#
#=    if strobe=#
#=        tsk = ThreadPools.@tspawnat 3 begin=#
#=            init_strobe_t=time()=#
#=            sleep(stim_offset)=#
#=            while (time()-init_strobe_t)<t-0.005=#
#=                stim_state="ON"; push!(stim_on_arr, time()- init_strobe_t)=#
#=                stim.high()=#
#=                sleep(p_w); stim.low()=#
#=                stim_state="OFF"=#
#=                push!(stim_off_arr, time()- init_strobe_t)=#
#=                sleep(period - (time()-(init_strobe_t+stim_offset))%period)=#
#=            end=#
#=        end=#
#=    end=#
#=    try=#
#=        while (img_ts-ts_init)<(t*1e9) && start_toggle[]=#
#=            img_id,img_ts,_ = getimage!(cam,img);=#
#=            n+=1=#
#=            if save_frame=#
#=                img_arr[:,:,((n-1)%cam_fps)+1].=reinterpret(UInt8,img)=#
#=            end=#
#=            if disp=#
#=                dsp= obs_img[]=UInt8.(floor.(img*255))[1:4:end,end:-4:1]=#
#=            end=#
#=            push!(ts_arr,img_ts)=#
#=            push!(id_arr,img_id)=#
#==#
#==#
#=            if save_frame && n%(cam_fps)==0=#
#=                wrt = write(file, img_arr)=#
#=                img_arr.=0=#
#=            end=#
#==#
#=            push!(fps,time())=#
#=            if stat=#
#=                print_fps(n,fps,ts_arr,stop=(fps[end]-fps[1])>t,stim= stim_state)=#
#=                sleep(sleept)=#
#=            elseif disp=#
#=                sleep(max(0.001,sleept))=#
#=            end=#
#=        end=#
#=    catch e=#
#=        println("\nAborting...")=#
#=        notes*="\n\nAborted early"=#
#=        #=if typeof(e) == InterruptException=#=#
#=            #=stop!(cam)=#=#
#=            #=println(e)=#=#
#=            #=rethrow(e)=#=#
#=        #=end=#=#
#=    end=#
#=    if strobe=#
#=        if !istaskdone(tsk)=#
#=            schedule(tsk,InterruptException();error=true)=#
#=        end=#
#=    end=#
#=    println("\nDone. Took $(round(fps[end]-fps[1])) s for $n frames. FPS = $(round(n/t,digits=1)).");=#
#=    stop!(cam);=#
#=    stim.low()=#
#=    ts_arr.-=ts_init=#
#=    ts_arr*=1e-9=#
#=    id_arr.+=1=#
#=    if save_frame =#
#=        if sum(img_arr)>0=#
#=            write(file, img_arr)=#
#=        end=#
#=        println("Saved $n frames to $fold_name...")=#
#=        stim_arr=zeros(size(ts_arr))=#
#=        for (i,o) in enumerate(stim_on_arr)=#
#=            stim_arr[ts_arr.>stim_on_arr[i] .&& (ts_arr.<stim_off_arr[i] .|| ts_arr.<(stim_on_arr[i]+0.1))].=1=#
#=        end=#
#=        CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr,fps.-fps[1],stim_arr],["ID","Cam","Grab","Stim"]))=#
#=        println("Enter note:")=#
#=        en_note_tsk=Threads.@sync readline()=#
#=        en_note=fetch(en_note_tsk)=#
#=        notes*="\n\n$en_note"=#
#=        notes*="\n\n$n frames in $(round(ts_arr[end],digits=2)) s"=#
#=        open("$fold_name/dat.txt", "w") do file=#
#=            write(file, fold_name*"\n\n"*cam_prop(cam)*"\n\nNotes:\n"*notes*"\n\n")=#
#=        end=#
#=        close(file)=#
#=    end=#
#=    return fps,id_arr,ts_arr,fold_name=#
#=end=#

function record_inf(cam;stat=false,obs_img=Nothing,disp=false,save_frame=false,sleept=0.001,sep=false,NOTES=Observable(Dict{String,Any}("stentor"=>"cool")),strobe=Observable(false),period=Observable(60),p_w=Observable(0.05),stim=nothing,stim_offset=0,start_toggle=Observable(false),stim_on=Observable(false),t_start=Observable(0),start_exp=Observable(false),ITI=3600,TRIAL_LENGTH=3600,led=Observable(true),abort=ABORT,DELAY=Observable(0),STAGE_NUM=Observable(1))
    cam_fps=Int(floor(framerate(cam)))
    stim_state=false
    beg_ts=0
    img=zeros(Gray{N0f8},2048,2048)
    n=1
    led_arr=[0]
    start!(cam);
    img_id,ts_init,_=getimage!(cam,img)
    start_t=time()
    fps=[start_t]
    img_ts=ts_init
    ts_arr=[ts_init]
    id_arr=[img_id]
    img_arr=zeros(UInt8,2048,2048,cam_fps)
    img_arr[:,:,1].=reinterpret(UInt8,img)
    stim_on_arr=[]
    stim_off_arr=[]
    stim_state="OFF"
    last_start=false
    n_start=0
    ts_start=0
    exp_ts_start=0
    tsk=nothing
    tstim=nothing
    exp_on=false
    file=nothing
    curr_trial=0
    exp_fold_name=""
    fold_name="/home/para/data/"*Dates.format(now(),folder_format)
    try
        while true
            img_id,img_ts,_ = getimage!(cam,img)
            #=println("$(start_toggle[]) $last_start")=#
            #=println(start_exp[])=#
            if !exp_on && start_exp[]
                exp_fold_name="/home/para/data/"*Dates.format(now(),folder_format)
                curr_trial=0
                exp_on=true
                exp_ts_start=time()
                println("\nStarting experiment\n")
                tsk=Threads.@async begin
                    exp_ts_start=time()
                    sleep(DELAY[])
                    start_toggle[] = true
                    sleep(TRIAL_LENGTH[])
                    start_toggle[]=false
                    sleep(ITI[])
                    start_toggle[]=true
                    sleep(TRIAL_LENGTH[])
                    start_exp[]=false
                end
            end
            if exp_on && !start_exp[] 
                sleep(0.01)
                exp_on=false
                start_toggle[]=false
                t_start[]=0
                sleep(0.01)
                if !istaskdone(tsk)
                    schedule(tsk,InterruptException();error=true)
                end
                if strobe[]
                    if !istaskdone(tstim)
                        schedule(tstim,InterruptException();error=true)
                    end
                end
                println("\n Experiment done")
            end
            if (start_toggle[] - last_start) == 1 
                curr_trial+=1
                fold_name = "$(exp_fold_name)/trial_$(curr_trial)"
                last_start=true
                n_start=1
                ts_start=time()
                if save_frame[]
                    mkpath(fold_name)
                    file=open("$fold_name/dat.bin","w+")
                    println("\nWill save to $fold_name")
                end
                println("\nStarting trial")
                led[]=true
                if strobe[]
                    println("Starting stimulus")
                    tstim=Threads.@async begin
                        try
                            sleep(stim_offset[])
                            while (time()-ts_start) < (TRIAL_LENGTH[]-1)
                                stim.high(STAGE_NUM[])
                                push!(stim_on_arr,time()-ts_start)
                                sleep(p_w[])
                                stim.low(STAGE_NUM[])
                                push!(stim_off_arr,time()-ts_start)
                                sleep(period[] - (time()-(ts_start+stim_offset[]))%period[])
                            end
                        catch e
                            if typeof(e)==InterruptException
                                println("Aborted stimulus")
                            end
                        end
                    end
                end
                ts_arr=[ts_init]
                id_arr=[img_id]
                fps=[ts_start]
            end
            n+=1
            if start_toggle[]
                n_start+=1
                if strobe[]
                    curr = (stim_offset[] < (time()-ts_start)%period[] < stim_offset[]+p_w[]) 
                    stim_on[] = curr
                end
                if save_frame[] && last_start
                    img_arr[:,:,((n_start-1)%cam_fps)+1].=reinterpret(UInt8,img)
                end
            end
            if start_exp[]
                t_start[]=Int(floor(time()-exp_ts_start))
            end
            if disp[]
                dsp= obs_img[]=UInt8.(floor.(img*255))[1:4:end,end:-4:1]
            else
                obs_img[]=rand(Gray{N0f8},2048,2048)
            end

            push!(ts_arr,img_ts)
            push!(id_arr,img_id)
            
            if save_frame[] && last_start && n_start%(cam_fps)==0
                wrt = write(file, img_arr)
                img_arr.=0
            end

            push!(fps,time())
            if stat
                print_fps(n,fps,ts_arr,stop=false,stim=start_toggle[])
                sleep(sleept)
            elseif disp[]
                sleep(max(0.001,sleept))
            end
            if (start_toggle[] - last_start) == -1
                last_start=false
                if strobe[]
                    if !istaskdone(tstim)
                        schedule(tstim,InterruptException();error=true)
                    end
                end
                #=led[]=false=#
                curr_time=time()
                #=println("\nDone. Took $(round(curr_time-ts_start,digits=2)) s for $n_start frames. FPS = $(round(n_start/((curr_time-ts_start)),digits=1)).");=#
                stim.low(STAGE_NUM[])
                ts_arr.-=ts_init
                ts_arr*=1e-9
                id_arr.+=1
                id_arr.-=id_arr[1]
                if save_frame[] 
                    if sum(img_arr)>0
                        write(file, img_arr)
                    end
                    println("Saved $n_start frames to $fold_name...")
                    stim_arr=zeros(size(ts_arr))
                    for (i,o) in enumerate(stim_on_arr)
                        stim_arr[ts_arr.>stim_on_arr[i] .&& (ts_arr.<stim_off_arr[i] .|| ts_arr.<(stim_on_arr[i]+0.1))].=1
                    end
                    CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr,fps.-fps[1],stim_arr],["ID","Cam","Grab","Stim"]))
                    CSV.write("$fold_name/stim.csv", DataFrame([stim_on_arr,stim_off_arr],["Stimulus on","Stimulus off"]))
                    #=if !start_exp[]=#
                    #=    println("Enter note:")=#
                    #=    en_note=readline()=#
                    #=else=#
                    #=    en_note=""=#
                    #=end=#
                    merge!(NOTES[],Dict{String,Any}("stimulus"=>strobe[], "display"=>disp[], "frames"=> n_start, "runtime" => round(time()-ts_start,digits=2),"camera"=>cam_prop(cam),"folder"=>fold_name))
                    open("$fold_name/dat.json", "w") do file
                            write(file, JSON.json(NOTES[]))
                    end
                    close(file)
                end
            end
            if ABORT[]
                stop!(cam)
                return "Aborted"
            end
        end
    catch e
        print("\nAborting...")
        stop!(cam)
        start_toggle[]=false
        if typeof(e) == InterruptException
            print(" (interrupted)")
        else
            println()
            println(e)
            rethrow(e)
        end
    end
    return fps,id_arr,ts_arr,fold_name
end




function fr(cam,n)
    framerate!(cam,n)
end

function print_stat(x,y,z="",a="",b="")
    print("\r",rpad.(x,10," "),lpad.(y,15," "),lpad.(z,15," "),lpad.(a,25," "),lpad.(b,15," "))
end

function disp(fig;x=500,y=500)
    screen=display(fig);
    resize!(screen,x,y);
end


function load_rpi(;flash_led=true,single_stim=false,gpio1=1,gpio2=3,gpio3=4,gpiol=14)
    rpi_port=readdir("/dev/")[findall(occursin.("ttyACM",readdir("/dev/")))]
    if isempty(rpi_port)
        println("No RPi")
    else
        println("Pyboard port: $(rpi_port[1])")
        stim=stim_init(;gpio1=gpio1,gpio2=gpio2,gpio3=gpio3,gpiol=gpiol,port=rpi_port[1][end:end])
        if single_stim
            #=stim.high()=#
            #=sleep(0.05)=#
            #=stim.low()=#
        end
        if flash_led
            stim.set_led(10,10,10)
            sleep(1)
            stim.set_led(0,0,0)
        end
        return stim
    end
end

function flash_led(stim)
    stim.set_led(10,10,10)
    sleep(1)
    stim.set_led(0,0,0)
end

function stim_one(stim,n;pulse=0.05,run_cam=false)
    if run_cam
        stat=record(cam,5;obs_img=obs_img,save_frame=false,disp=true,stat=true,notes="",strobe=true,p_w=pulse,period=21,stim=stim,stim_offset=2);
    else
        stim.high(n)
        sleep(pulse)
        stim.low(n)
    end
end


function rpi_disconnect(stim)
    global stim=nothing
    GC.gc()
end
