using GLMakie, Images, ThreadPools, ProgressBars, Dates, CSV, DataFrames, JLD, PyCall, HDF5, Mmap, VideoIO, ProgressMeter, Spinnaker #load Spinnaker last
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
        print(cam_prop(cam))
    end
    return cam
end

function cam_prop(cam)
    prop_str="-"^70*"\n\n Model: $cam \n\n"*"-"^70*" \n\n"
    prop_str*= " Exposure: $(round(exposure(cam)[1]/1000,digits=2)) ms \n"
    prop_str*= " Framerate: $(framerate(cam)) fps \n"
    prop_str*= " Trigger: $(triggermode(cam)) \n"
    prop_str*= " Buffer Mode: $(buffermode(cam)) \n"
    prop_str*= " Buffer Count: $(buffercount(cam)[1]) \n\n"
    prop_str*= "-"^70*"\n"
    return prop_str
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

function record(cam,t=0;stat=false,obs_img=Nothing,disp=false,save_frame=false,fold_name="/home/para/data/"*Dates.format(now(),folder_format),sleept=0.0001,sep=false,notes="",strobe=false,period=2,p_w=1,stim=nothing,stim_offset=0)
    cam_fps=Int(floor(framerate(cam)))
    stim_state=false
    if save_frame
        mkpath(fold_name)
        file=open("$fold_name/dat.bin","w+")
    end
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
    if strobe
        tsk = Threads.@spawn begin
            init_strobe_t=time()
            while (time()-init_strobe_t)<t-0.005
                stim_state="ON"; push!(stim_on_arr, time()- init_strobe_t)
                stim.high()
                sleep(p_w); stim.low()
                stim_state="OFF"
                push!(stim_off_arr, time()- init_strobe_t)
                sleep(period - (time()-init_strobe_t)%period)
            end
        end
    end
    try
        while (img_ts-ts_init)<(t*1e9)
            img_id,img_ts,_ = getimage!(cam,img);
            n+=1
            if save_frame
                img_arr[:,:,((n-1)%cam_fps)+1].=reinterpret(UInt8,img)
            end
            if disp
                dsp= obs_img[]=UInt8.(floor.(img*255))[1:4:end,end:-4:1]
            end
            push!(ts_arr,img_ts)
            push!(id_arr,img_id)
           

            if save_frame && n%(cam_fps)==0
                wrt = write(file, img_arr)
                img_arr.=0
            end

            push!(fps,time())
            if stat
                print_fps(n,fps,ts_arr,stop=(fps[end]-fps[1])>t,stim= stim_state)
                sleep(sleept)
            elseif disp
                sleep(max(0.001,sleept))
            end
        end
    catch e
        println("\nAborting...")
        println(e)
        schedule(tsk, InterruptException();error=true)
    end

    println("\nDone. Took $(round(fps[end]-fps[1])) s for $n frames. FPS = $(round(n/t,digits=1)).");
    stop!(cam);
    stim.low()
    ts_arr.-=ts_init
    ts_arr*=1e-9
    id_arr.+=1
    if save_frame 
        if sum(img_arr)>0
            write(file, img_arr)
        end
        println("Saved $n frames to $fold_name...")
        stim_arr=zeros(size(ts_arr))
        for (i,o) in enumerate(stim_on_arr)
            stim_arr[ts_arr.>stim_on_arr[i] .&& (ts_arr.<stim_off_arr[i] .|| ts_arr.<(stim_on_arr[i]+0.1))].=1
        end
        CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr,fps.-fps[1],stim_arr],["ID","Cam","Grab","Stim"]))
        open("$fold_name/dat.txt", "w") do file
            write(file, fold_name*"\n\n"*cam_prop(cam)*"\n\nNotes:\n"*notes*"\n\n")
        end
        close(file)
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
