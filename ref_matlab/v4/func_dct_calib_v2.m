function DCT_image = func_DCT_calib(DCT_img_temp)


i=1;
k=1;
x=1;
for j = 1 : 16
    if j == 1
        DCT_image( 16*(k-1)+j , 16*(i-1)+ 1 ) = double(DCT_img_temp(j   ,1)*2);
        % DCT_image( 16*(k-1)+j , 16*(i-1)+ 2 ) = double(DCT_img_temp(j,2))/2;

        DCT_image( 16*(k-1)+j , 16*(i-1)+ 2 ) = double(DCT_img_temp(j,2))*2;
    elseif j == 2
        DCT_image( 16*(k-1)+j , 16*(i-1)+ 1 ) = double(DCT_img_temp(j   ,1)*2);
        DCT_image( 16*(k-1)+j , 16*(i-1)+ 2 ) = double(DCT_img_temp(j,2))/2;
    else
        DCT_image( 16*(k-1)+j , 16*(i-1)+ 1 ) = double(DCT_img_temp(j   ,1))/2;
        DCT_image( 16*(k-1)+j , 16*(i-1)+ 2 ) = double(DCT_img_temp(j,2))/2;
    end

    DCT_image( 16*(k-1)+j , 16*(i-1)+ 3 ) = double(DCT_img_temp(j,3))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 4 ) = double(DCT_img_temp(j,4))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 5 ) = double(DCT_img_temp(j,5))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 6 ) = double(DCT_img_temp(j,6))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 7 ) = double(DCT_img_temp(j,7))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 8 ) = double(DCT_img_temp(j,8))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+ 9 ) = double(DCT_img_temp(j,9))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+10 ) = double(DCT_img_temp(j,10))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+11 ) = double(DCT_img_temp(j,11))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+12 ) = double(DCT_img_temp(j,12))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+13 ) = double(DCT_img_temp(j,13))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+14 ) = double(DCT_img_temp(j,14))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+15 ) = double(DCT_img_temp(j,15))/2;
    DCT_image( 16*(k-1)+j , 16*(i-1)+16 ) = double(DCT_img_temp(j,16))/2;
end