delete wave *
add wave *
force -deposit /pulse 1 0, 0 10 -r 20
force reset_n 1
run 100
force reset_n 0
run 50
force reset_n 1
run 50
force up 0
force down 0
run 100
force up 1
run 500

