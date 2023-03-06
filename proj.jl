using GLMakie
for i in 1:10
    rectangle = rect(ax,:blue)
    sleep(0.2)
    rectangle = rect(ax,:black)
    sleep(0.2)
end
