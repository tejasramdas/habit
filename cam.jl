using GLMakie, Images, ThreadPools, ProgressBars, Dates, CSV, DataFrames, JLD, PyCall, HDF5, Spinnaker #load Spinnaker last

# NOTES
# - image timestamp units: 10e-5 ms

folder_format="yyyy_mm_dd_HH_MM_SS"

function led_init()
    pushfirst!(PyVector(pyimport("sys")."path"), ".")
    return pyimport("led").LED()
end

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
    @tspawnat 2 image!(ax,obs_img)
    return f
end

function init_img()
    img=rand(UInt8,2048,2048)
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
        obs_img[]=UInt8.(floor.(img*255))[:,end:-1:1];
    end
    stop!(cam);
    return img
end

function print_fps(i, fps, img_ts;stop=false)
    if stop
        print_stat(i, "Stopped Cam", "$(round(1/(fps[end]-fps[end-1]),digits=1)) FPS Grab","$(round(fps[end]-fps[1],digits=3)) s")
    else
        print_stat(i, "$(round(10e8/(img_ts[end]-img_ts[end-1]),digits=1)) FPS Cam", "$(round(1/(fps[end]-fps[end-1]),digits=1)) FPS Grab","$(round(fps[end]-fps[1],digits=3)) s")
    end
end

function plot_stats(stats)
    fig=Figure()
    ax1=GLMakie.Axis((fig[1,1]))
    ax2=GLMakie.Axis((fig[1,2]))
    lines!(ax1,(stat[1].-stat[1][1]))
    lines!(ax1,(stat[3].-stat[3][1])/1000)
    lines!(ax2,diff(stat[1]))
    lines!(ax2,diff(stat[3])/1000)
    buffercheck=2*(1000*diff(stat[1]).>diff(stat[3])).-1
    buffercount=[0]
    for i in buffercheck
        push!(buffercount,min(45,max(0,buffercount[end]+i)))
    end
    lines!(ax2,buffercount/45)
    disp(fig,x=1000)
end

function record(cam,t=0;stat=false,obs_img=Nothing,disp=false,save_frame=false,fold_name="/ssd/"*Dates.format(now(),folder_format),sleept=0,sep=false,notes="",led_strobe=false,period=2,p_w=1,led=nothing,led_offset=0)
    cam_fps=Int(floor(framerate(cam)))
    if save_frame
        mkpath(fold_name)
        file=h5open("$fold_name/dat.h5","w")
    end
    beg_ts=0
    img=zeros(Gray{N0f8},2048,2048)
    n=1
    led_arr=[0]
    start!(cam);
    if led_strobe
        print("LED")
        @tspawnat 2 flash_led(led,t,p_w,period,offset=led_offset)
    end
    _,ts_init,_=getimage!(cam,img)
    fps=[time()]
    img_ts=ts_init
    ts_arr=[img_ts]
    ts_arr=[ts_init]
    id_arr=[1]
    img_arr=zeros(UInt8,2048,2048,cam_fps)
    img_arr[:,:,1].=reinterpret(UInt8,img)
    while (img_ts-ts_init)<t*10e8
        img_id,img_ts,_ = getimage!(cam,img);
        n+=1
        if save_frame
            img_arr[:,:,((n-1)%cam_fps)+1].=reinterpret(UInt8,img)
        end
        if disp
            obs_img[]=(img)[:,end:-1:1];
        end
        push!(ts_arr,img_ts)
        push!(id_arr,img_id)
        if led_strobe
            push!(led_arr,Int(((img_ts-ts_init)*10e-8)%period>p_w))
        else
            push!(led_arr,0)
        end
        if save_frame && n%cam_fps==0
            write(file, "$n", img_arr)
            img_arr.=0
        end
        push!(fps,time())
        if stat
            print_fps(n,fps,ts_arr,stop=(fps[end]-fps[1])>t)
            sleep(sleept)
        elseif disp
            sleep(max(0.001,sleept))
        end
    end
    println("\nDone. Took $(round(fps[end]-fps[1])) s for $n frames. FPS = $(round(n/t,digits=1)).");
    stop!(cam);
    ts_arr=(ts_arr.-ts_init)/10e5
    if save_frame 
        if sum(img_arr)>0
            write(file, "$n", img_arr)
            img_arr=Nothing
        end
        println("Saved $n frames to $fold_name...")
        CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr,fps.-fps[1],led_arr],["ID","Cam","Grab","LED"]))
        open("$fold_name/dat.txt", "w") do file
            write(file, fold_name*"\n\n"*cam_prop(cam)*"\n\nNotes:\n"*notes*"\n\n")
        end
        close(file)
    end
    return fps,id_arr,ts_arr
end

function fr(cam,n)
    framerate!(cam,n)
end

function print_stat(x,y,z="",a="")
    print("\r",rpad.(x,10," "),lpad.(y,20," "),lpad.(z,20," "),lpad.(a,20," "))
end

cam=init_cam(40,10000,"";prop=true);

# obs_img=init_img();

# fig=init_disp(obs_img);

function disp(fig;x=500,y=500)
    screen=display(fig);
    resize!(screen,x,y);
end


function flash_led(led,t=0,p_w=0,period=0;offset=0)
    beg=time()
    curr_t=0
    x=[]
    while curr_t<(t-0.001)
        curr_t=time()-beg
        if curr_t>offset
            if (curr_t-offset)%period<p_w
                push!(x,1)
                led.high()
            else
                push!(x,0)
                led.low()
            end
        end
        curr_t=time()-beg
    end
    led.low()
    return x
end

led=led_init()

led.high()
led.low()

# img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);


# stat=record(cam,5;save_frame=true,disp=false,stat=true);

SAVE_FRAME=true

stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes="Small well test 2");

# stat=record(cam,5;save_frame=SAVE_FRAME,disp=false,stat=true,notes="Testing LED",led_strobe=true,p_w=0.2,period=1,led=led);

# plot_stats(stat);



# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end
