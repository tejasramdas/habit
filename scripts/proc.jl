using Images, GLMakie, ProgressBars, FFTW, HDF5, PaddedViews, CSV, DataFrames, Mmap, VideoIO

struct LazyStack
    loc::String
    count::Int
    keys::Vector{Int}
    chunk::Int
    curr_range::Int
    frames::Array{UInt8,3}
    info::DataFrame
end

function convert_h5(fold_name)
    file_loc="/home/para/data/"*fold_name*"/dat."
    println(file_loc)
    file=h5open(file_loc*"h5")
    binarr=open(file_loc*"bin","w+")
    sort_keys=string.(sort(parse.(Int,collect(keys(file)))))
    write(binarr,read(file[sort_keys[1]]))
    for i in tqdm(2:size(sort_keys)[1])
        write(binarr,read(file[sort_keys[i]]))
    end
    close(file)
    close(binarr)
    println("Converted $file_loc...")
end

function load_stack(master_folder="/home/para/data/",fold_name=readdir(master_folder)[end];num_frames=0,sz=2048,down=false)
    file_loc="$master_folder$fold_name/dat"
    frame_info=CSV.read(file_loc*".csv",DataFrame)
    notes=read(open(file_loc*".txt","r"),String)
    println("Loading file...")
    if num_frames==0
        frame_num = Int(frame_info.ID[end]-1)
    else
        frame_num=num_frames
    end
    if down
        binarr=open(file_loc*"2.bin")
    else
        binarr=open(file_loc*".bin")
    end
    arr = mmap(binarr, Array{UInt8,3}, (sz,sz,frame_num))
    println("Loaded $file_loc... $(frame_num) frames")
    return arr,frame_info,notes
end

function load_stack_h5(fold_name=readdir("/home/para/data")[end])
    file_loc="/home/para/data/"*fold_name*"/dat."
    frame_info=CSV.read(file_loc*"csv",DataFrame)
    file=h5open(file_loc*"h5")
    dat=read(file)
    sort_keys=string.(sort(parse.(Int,collect(keys(dat)))))
    arr=temp=dat[sort_keys[1]]
    for i in tqdm(2:size(sort_keys)[1])
        arr=cat(arr,dat[sort_keys[i]],dims=3)
    end
    close(file)
    println("Loaded $file_loc...")
    return arr[:,:,1:parse(Int,sort_keys[end])],frame_info
end

function lazy_load_stack(fold_name=readdir("/home/para/data")[end])
    file_loc="/home/para/data/"*fold_name*"/dat."
    frame_info=CSV.read(file_loc*"csv",DataFrame)
    file=h5open(file_loc*"h5")
    sort_keys=sort(parse.(Int,collect(keys(file))))
    lazy_stack=LazyStack(file_loc,sort_keys[end],sort_keys,diff(sort_keys)[1],sort_keys[1],read(file["$(sort_keys[1])"]),frame_info)
    close(file)
    println("Loaded $file_loc...")
    return lazy_stack
end

function transform(img_arr)
    for i in tqdm(1:size(img_arr)[1])
        img_arr[i]=rotr90(img_arr[i])[end:-1:1,:]
    end
    return img_arr
end

function compute_diff(img_arr,fold_name;diff_step=1,step=500)
    diff_step=1
    file_loc="/home/para/data/"*fold_name*"/diff"
    num_frames=size(img_arr)[3]
    if !("diff_$(diff_step).bin" in readdir(file_loc[1:end-5]))
        println("Computing...")
        binarr=open(file_loc*"_$(diff_step).bin","w+")
        for i in 1:step:num_frames
            write(binarr,diff(Float16.(img_arr[:,:,i:min(i+step,num_frames)])/Float16(255.0),dims=3))
        end
        close(binarr)
    end
    binarr=open(file_loc*"_$(diff_step).bin")
    println(file_loc*"_$(diff_step).bin")
    arr = mmap(binarr, Array{Float16,3}, (2048,2048,num_frames-1))
    println(size(arr))
    close(binarr)
    return arr
end

function frameshift(f,obs,lim,trig)
    listen=on(events(f).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if event.key == Keyboard.enter
                obs[]=(obs[]%lim)+1
                notify(trig)
            elseif event.key == Keyboard.space
                obs[]=((obs[]+lim-2)%lim)+1
                notify(trig)
            end
        end
    end
    return listen
end

function save_video(img_arr, stim)
    f=Figure(res=(1000,1000)); 
    ax1=GLMakie.Axis(f[1,1]); 
    padded_img=PaddedView(0,img_arr,(-win_width:size(img_arr)[1]+win_width,-win_width:size(img_arr)[2]+win_width,1:size(img_arr)[3]))
    padded_diff=PaddedView(0,diff_arr,(-win_width:size(diff_arr)[1]+win_width,-win_width:size(diff_arr)[2]+win_width,1:size(diff_arr)[3]))
    title = Label(f[0, :], @lift("Frame: $($to_img*$frame_num) | Origin: $($p_x), $($p_y)"), fontsize = 20)
    img_plot=image!(ax1,@lift(reinterpret(N0f8,padded_img[$p_x:p_x[]+win_width,$p_y:p_y[]+win_width,to_img*frame_num[]])),interpolate=false)
    diff_plot=image!(ax2,@lift(max.($threshold,padded_diff[$p_x:p_x[]+win_width,$p_y:p_y[]+win_width,frame_num[]]).-threshold[]),interpolate=false)
    # diff_histo=hist!(ax3,@lift(diff_arr[1:4:end,1:4:end,$frame_num][:]),bins=collect(-1.0:0.1:1.0))
    return f,ax1,ax2,diff_plot
end


function make_plot(img_arr,diff_arr,ts,stim;win_width=100)
    f=Figure(res=(500,500)); 
    ax1=GLMakie.Axis(f[2:10,1:9]); 
    # ax2=GLMakie.Axis(f[1,2]); 
    # ax3=GLMakie.Axis(f[2,:]);
    padded_img=PaddedView(0,img_arr,(-win_width:size(img_arr)[1]+win_width,-win_width:size(img_arr)[2]+win_width,1:size(img_arr)[3]))
    # padded_diff=PaddedView(0,diff_arr,(-win_width:size(diff_arr)[1]+win_width,-win_width:size(diff_arr)[2]+win_width,1:size(diff_arr)[3]))
    #=title = Label(f[1,1:9], @lift("Time: $(round(ts[$to_img*$frame_num],digits=1)) | Offset: $($p_x), $($p_y) | Stim: $(stim[$to_img*$frame_num])"), fontsize = 18)=#
    # img_plot=image!(ax1,@lift(reinterpret(N0f8,padded_img[$p_x:p_x[]+win_width,$p_y:p_y[]+win_width,to_img*frame_num[]])),interpolate=false)
    img_plot=image!(ax1,@lift(reinterpret(N0f8,img_arr[:,:,to_img*$frame_num])),interpolate=false)
    # diff_plot=image!(ax2,@lift(max.($threshold,padded_diff[$p_x:p_x[]+win_width,$p_y:p_y[]+win_width,frame_num[]]).-threshold[]),interpolate=false)
    # diff_histo=hist!(ax3,@lift(diff_arr[1:4:end,1:4:end,$frame_num][:]),bins=collect(-1.0:0.1:1.0))
    # hidedecorations!(ax1)
    return f,ax1#ax2,diff_plot
end

function show_plot(f=plt[1])
    screen=display(f)
    resize!(screen, 500,500)
    # hidedecorations!(ax1)
    # hidedecorations!(ax2)
end

function zoom(x_l=0,y_l=0,win=100;plt=plt)
    ax1=plt[2]
    ax2=plt[3]
    xlims!(ax1,x_l,x_l+win)
    xlims!(ax2,x_l,x_l+win)
    ylims!(ax1,y_l,y_l+win)
    ylims!(ax2,y_l,y_l+win)
end

function res(plt=plt)
    zoom(0,0,win_width,plt=plt)
end

function bandpass(img,l=1,h=size(img)[1])
    fft_img = fft(Float16.(img))
    fft_img[1:l,1:l] .= 0
    fft_img[h:end,h:end] .= 0
    ifft_img = abs.(ifft(fft_img))
end

# filter_plot=image!(ax,@lift(bandpass(reinterpret(N0f8,img_arr[:,:,$frame_num]))))
#

function track(diff_arr,b_x=0,b_y=0;win_width=100,f_start=1,num_frames=size(diff_arr)[3],plot_path=false,plt=nothing,blob_s=[5,10,20],thresh=0.02)
    hist_x=Int[]
    hist_y=Int[]
    for i in tqdm(f_start:2:f_start+num_frames-1)
        padded_diff=PaddedView(0,max.(thresh,diff_arr[:,:,i]).-thresh,(-win_width:size(diff_arr[:,:,i])[1]+win_width,-win_width:size(diff_arr[:,:,i])[2]+win_width))
        blo=blob_LoG(padded_diff[b_x:b_x+win_width,b_y:b_y+win_width],blob_s)
        # print(size(blo)[1],", ")
        scat=map(x->(x.location[1],x.location[2]),blo)
        if size(scat)[1]>0
            peak=scat[findmax(map(x->x.amplitude,blo))[2]]
            push!(hist_x,b_x+peak[1])
            push!(hist_y,b_y+peak[2])
            b_x+=peak[1]-Int(floor(win_width/2))
            b_y+=peak[2]-Int(floor(win_width/2))
        else
            println("Couldn't find anything in frame $i")
            break
        end
    end
    track_plot=Nothing
    shift=Nothing
    if plot_path
        shift=on(frame_num,weak=true) do val
            try
                p_x.val=hist_x[val]-win_width//2
                p_y[]=hist_y[val]-win_width//2
                # println("Center: ($(hist_x[val]),$(hist_y[val]))")
            catch
                println("Nothing found :(")
            end
            try
                delete!(plt[3],track_plot)
            catch
            end
            try
                track_plot=arrows!(plt[3],[win_width/2],[win_width/2],[diff(hist_x)[frame_num[]]],[diff(hist_y)[frame_num[]]],arrowcolor=:red, linecolor=:red, linewidth=2)
            catch
            end
        end
    end
    return hist_x, hist_y, track_plot, shift
end

function upc(a,b)
    p_x[]=a
    p_y[]=b
end


function write2video(imgstack,fold_name;crf=21,fps=10)
    encoder_options = (crf=crf, preset="medium")
    # I want a progress bar but doing it frame by frame is too slow :/
    # open_video_out("$fold_name.mp4", imgstack[:,:,1], framerate=fps, encoder_options=encoder_options) do writer
    #     @showprogress for frame in 1:size(img_arr)[3]
    #         write(writer, img_arr[:,:,frame])
    #     end
    # end
    VideoIO.save("$fold_name.mp4", [imgstack[:,:,i] for i in 1:size(imgstack)[end]], framerate=fps, encoder_options=encoder_options)
end

#=function extract_stim_frames(imgstack,fold_name)=#
#==#
#=end=#
#################

