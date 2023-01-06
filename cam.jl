using GLMakie, Images, ThreadPools, ProgressBars, Dates, CSV, DataFrames, JLD, PyCall, Spinnaker #load Spinnaker last

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
        buffercount!(cam, 2*framerate)
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
    img=rand(Float32,2048,2048)
    obs_img=Observable(img)
    return obs_img
end

function get_one_frame(cam,obs_img;sleept=0,save=false)
    start!(cam);
    sleep(sleept)
    img=zeros(Float32,2048,2048)
    if save
        saveimage(cam,"test",spinImageFileFormat(5));
    else
        img_id, img_ts, img_exp = getimage!(cam,img);
        obs_img[]=(img)[:,end:-1:1];
    end
    stop!(cam);
    return img
end

function print_fps(i, beg, fps)
    print_stat(i, "$(round(fps[end]-fps[end-1],digits=4)) s", "$(round(fps[end]-beg,digits=4)) s")
end

function get_many_frames(cam,n;stat=false,sleept=0,obs_img=Nothing,disp=false,save=false,fold_name=Dates.format(now(),folder_format))
    start!(cam);
    beg=time()
    fps=[beg]
    ts_arr=[]
    id_arr=[]
    img_arr=[]
    img=zeros(Float32,2048,2048)
    for i in 1:n
        img_id, img_ts, img_exp = getimage!(cam,img);
        push!(img_arr,img)
        if disp
            obs_img[]=(img)[:,end:-1:1];
        end
        push!(ts_arr,img_ts)
        push!(id_arr,img_id)
        push!(fps,time())
        if stat
            print_fps(i,beg,fps)
            sleep(sleept)
        else
            sleep(max(0.001,sleept))
        end
    end
    println("\nDone. Took $(round(fps[end]-beg)) s for $n frames.");
    stop!(cam);
    ts_arr=round(ts_arr/10e15,digits=3)
    if save
        mkdir(fold_name)
        println("Saving $n frames:")
        for i in tqdm(1:n)
            Images.save("$(fold_name)/img_$(lpad(i,5,"0")).png",rotr90(img_arr[i])[:,end:-1:1])
        end
        CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr],["ID","TD"]))
    end
    return round.(ts_arr/10e15,3), id_arr
end

function record(cam;t=0,frames=0,stat=false,obs_img=Nothing,disp=false,save_frame=false,fold_name="frames/"*Dates.format(now(),folder_format),sleept=0,sep=false)
    cam_fps=framerate(cam)
    if t==0
        t=frames/framerate(cam)
    end
    if save_frame
        mkdir(fold_name)
    end
    start!(cam);
    beg=time()
    beg_ts=0
    fps=[beg]
    ts_arr=[]
    id_arr=[]
    img=zeros(Float32,2048,2048)
    img_arr=[]
    n=0
    while ((fps[end]-beg)<t)
        img_id, img_ts, img_exp = getimage!(cam,img);
        if n==0
            beg_ts=img_ts
        end
        push!(img_arr,deepcopy(img))
        if disp
            obs_img[]=(img)[:,end:-1:1];
        end
        push!(ts_arr,img_ts)
        push!(id_arr,img_id)
        push!(fps,time())
        n+=1
        if stat
            print_fps(n,beg,fps)
            sleep(sleept)
        else
            sleep(max(0.001,sleept))
        end
        if save_frame && n%cam_fps==0
            JLD.save("$fold_name/data_$(lpad.("$n",4,"0")).jld", "frames", img_arr)
            img_arr=[]
        end
    end
    println("\nDone. Took $(round(fps[end]-beg)) s for $n frames.");
    stop!(cam);
    ts_arr=(ts_arr.-beg_ts)/10e5
    if save_frame && n%40!=0
        JLD.save("$fold_name/data_$(lpad.("$n",4,"0")).jld", "frames", img_arr)
        img_arr=[]
        println("Saved $n frames to $fold_name...")
        CSV.write("$fold_name/dat.csv", DataFrame([id_arr,ts_arr,fps.-beg],["ID","Cam","Grab"]))
        open("$fold_name/dat.txt", "w") do file
            write(file, cam_prop(cam))
        end
    end
    return true
end


function print_stat(x,y,z="")
    print("\r",rpad.(x,20," "),lpad.(y,20," "),lpad.(z,20," "))
end

cam=init_cam(40,10000,"";prop=true);

obs_img=init_img();

fig=init_disp(obs_img);

function disp()
    screen=display(fig);
    resize!(screen, 500, 500);
end

img=get_one_frame(cam,obs_img);

println("READY");

# get_many_frames(cam,img,obs_img,100);

ts_arr,id_arr=record(cam,t=20,save_frame=true,obs_img=obs_img,disp=false,stat=true);

# ts_arr,id_arr=record(cam,t=20,save_frame=false,obs_img=obs_img,disp=true,stat=true);

# while true
    # print("Enter command: ")
    # inp=readline()
    # if inp=="p"
        # print(cam_prop(cam))
    # end
# end
