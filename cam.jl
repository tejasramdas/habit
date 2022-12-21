using GLMakie, Images, Spinnaker #load Spinnaker last

function init_cam()
    cam=CameraList()[0]
    exposure!(cam,0.05e6)
    # framerate!(cam,60)
    triggersource!(cam, "Software")
    triggermode!(cam, "Off")
    acquisitionmode!(cam, "Continuous")
    buffermode!(cam, "NewestOnly")
    # buffermode!(cam, "OldestFirst")
    return cam
end

function init_display(obs_img):
    f=Figure()
    ax=GLMakie.Axis(f[1,1])
    image!(ax,obs_img)
end

function init_img()
    img=zeros(Float32,2048,2048)
    disp_img=Observable(img)
    return img,disp_img
end

function get_one_frame(img,disp_img,save=false)
    start!(cam)
    img_id, img_ts, img_exp = getimage!(cam,img);
    disp_img[]=(img)[:,end:-1:1];
    if save:
        Images.save("test.png", img)
    end
    stop!(cam)
end

function get_many_frames(img,obs_img,n,save=false)
    start!(cam)
    ts_arr=[]
    id_arr=[]
    for i in 1:n
        img_id, img_ts, img_exp = getimage!(cam,img);
        disp_img[]=(img)[:,end:-1:1];
        if save:
            Images.save("test_$i.png",rotr90(img)[:,end:-1:1])
        end
        println(i)
        push!(ts_arr,img_ts)
        push!(id_arr,img_id/10e9)
    end
    stop!(cam)
end
