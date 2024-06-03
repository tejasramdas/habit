using GLMakie

function init_img()
    img=rand(UInt8,512,512)
    obs_img=Observable(img)
    return obs_img
end

function init_disp(obs_img)
    f=Figure()
    ax=GLMakie.Axis(f[1,1])
    hidedecorations!(ax)
    resize!(f, (512, 512)) 
    image!(ax,obs_img)
    return f
end



obs_img=init_img();
fig=init_disp(obs_img);
display(fig)

