using Images, GLMakie, ProgressBars, FFTW, HDF5, PaddedViews


function load_stack(fold_name=readdir("/ssd")[end])
    file_loc="/ssd/"*fold_name*"/dat.h5"
    file=h5open(file_loc)
    dat=read(file)
    temp=[]
    for i in keys(dat)
        push!(temp,dat[i])
    end
    close(file)
    println("Loaded $file_loc...")
    return cat(temp...,dims=3)
end

function transform(img_arr)
    for i in tqdm(1:size(img_arr)[1])
        img_arr[i]=rotr90(img_arr[i])[end:-1:1,:]
    end
    return img_arr
end

img_arr=zeros(UInt8,2048,2048,20)

diff_arr=diff(Float16.(img_arr)/Float16(255.0),dims=3);

frame_num=Observable(1)
to_img=Observable(1)
threshold=Observable(0.0)

function frameshift(f,obs,lim)
    listen=on(events(f).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat)
            if event.key == Keyboard.enter
                obs[]=(obs[]%lim)+1
            elseif event.key == Keyboard.space
                obs[]=((obs[]+lim-2)%lim)+1
            end
        end
    end
    return listen
end


function make_plot()
    f=Figure(res=(1000,1000)); 
    ax1=GLMakie.Axis(f[1,1]); 
    ax2=GLMakie.Axis(f[1,2]); 
    # ax3=GLMakie.Axis(f[2,:]);
    title = Label(f[0, :], @lift("Frame: $($to_img*$frame_num) | Origin: $($(ax2.finallimits).origin[1]),  $(ax2.finallimits[].origin[2]) "), fontsize = 20)
    img_plot=image!(ax1,@lift(reinterpret(N0f8,img_arr[:,:,$to_img*$frame_num])),interpolate=false)
    diff_plot=image!(ax2,@lift(max.($threshold,diff_arr[:,:,$frame_num]).-threshold[]),interpolate=false)
    # diff_histo=hist!(ax3,@lift(diff_arr[1:4:end,1:4:end,$frame_num][:]),bins=collect(-1.0:0.1:1.0))
    listen=frameshift(f,frame_num,size(diff_arr)[end])
    return f,ax1,ax2,diff_plot,listen
end

function show_plot(f=plt[1])
    screen=display(f)
    resize!(screen, 1000,500)
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
    zoom(0,0,2048,plt=plt)
end

function bandpass(img,l=1,h=size(img)[1])
    fft_img = fft(Float16.(img))
    fft_img[1:l,1:l] .= 0
    fft_img[h:end,h:end] .= 0
    ifft_img = abs.(ifft(fft_img))
end

# filter_plot=image!(ax,@lift(bandpass(reinterpret(N0f8,img_arr[:,:,$frame_num]))))
#

function track(diff_arr,b_x=0,b_y=0;win_width=100,f_start=1,num_frames=size(diff_arr)[3],plot=false,plt=nothing,blob_s=[5,10,20],thresh=0.02)
    hist_x=Int[]
    hist_y=Int[]
    padded_diff=PaddedView(0,max.(thresh,diff_arr).-thresh,(-win_width:size(diff_arr)[1]+win_width,-win_width:size(diff_arr)[2]+win_width,1:size(diff_arr)[3]))
    for i in f_start:f_start+num_frames-1
        blo=blob_LoG(padded_diff[b_x:b_x+win_width,b_y:b_y+win_width,i],blob_s)
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
    if plot
        shift=on(frame_num,weak=true) do val
            try
                xlims!(plt[2],hist_x[val]-win_width*2,hist_x[val]+win_width*2)
                ylims!(plt[2],hist_y[val]-win_width*2,hist_y[val]+win_width*2)
                xlims!(plt[3],hist_x[val]-win_width*2,hist_x[val]+win_width*2)
                ylims!(plt[3],hist_y[val]-win_width*2,hist_y[val]+win_width*2)
                # println("Center: ($(hist_x[val]),$(hist_y[val]))")
            catch
                println("Nothing found :(")
            end
        end
        track_plot=arrows!(plt[3],hist_x[1:end-1],hist_y[1:end-1],diff(hist_x),diff(hist_y),arrowcolor=:red, linecolor=:red, linewidth=2)
    end
    return hist_x,hist_y, track_plot, shift
end



#################


img_arr=load_stack();

to_img[]=4

diff_arr=diff(Float16.(img_arr[:,:,1:to_img[]:end])/Float16(255.0),dims=3);

plt=make_plot()

show_plot()

x,y,p,s=track(diff_arr,1940,780,win_width=50,plot=true,plt=plt,blob_s=[5,10,20],thresh=0.03)
