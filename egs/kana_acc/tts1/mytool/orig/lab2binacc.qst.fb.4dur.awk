#!/usr/bin/awk -f
# cra2hts.awk : 

BEGIN{
  toms = 10000; # htk time -> ms
  fs = 5;
  stsize = 5;
  phsize = 56;
  phind["x"]=0;
  phind["A"]=1;
  phind["A1"]=2;
  phind["A2"]=3;
  phind["B"]=4;
  phind["D"]=5;
  phind["E"]=6;
  phind["E1"]=7;
  phind["E2"]=8;
  phind["F"]=9;
  phind["F^"]=10;
  phind["G"]=11;
  phind["H"]=12;
  phind["HY"]=13;
  phind["HY^"]=14;
  phind["I"]=15;
  phind["I1"]=16;
  phind["I2"]=17;
  phind["K"]=18;
  phind["KY"]=19;
  phind["KY^"]=20;
  phind["K^"]=21;
  phind["M"]=22;
  phind["N"]=23;
  phind["O"]=24;
  phind["O1"]=25;
  phind["O2"]=26;
  phind["P"]=27;
  phind["PY"]=28;
  phind["PY^"]=29;
  phind["P^"]=30;
  phind["Q"]=31;
  phind["R"]=32;
  phind["S"]=33;
  phind["SY"]=34;
  phind["SY^"]=35;
  phind["S^"]=36;
  phind["T"]=37;
  phind["TS"]=38;
  phind["TS^"]=39;
  phind["TY"]=40;
  phind["TY^"]=41;
  phind["U"]=42;
  phind["U1"]=43;
  phind["U2"]=44;
  phind["W"]=45;
  phind["Y"]=46;
  phind["Z"]=47;
  phind["ZY"]=48;
  phind["c^"]=49;
  phind["cl"]=50;
  phind["n"]=51;
  phind["n1"]=52;
  phind["n2"]=53;
  phind["pau"]=54;
  phind["sil"]=55;
  phind["y"]=56;
}

{
# extract phoneme info.
  split($3, a, /\$/);
  split(a[2], b, /-/);
  split(b[2], c, /+/);
  split(c[2], d, /@/);
  split(d[2], e, /\//);
  ph[1] = a[1];
  ph[2] = b[1];
  ph[3] = c[1];
  ph[4] = d[1];
  ph[5] = e[1];

  for(i=1;i<=5;i++){
      for(j=1;j<=phsize;j++){
	  phbin[i,j] = 0;
      }
      phbin[i,phind[ph[i]]] = 1;
  }
  
# extract accent info.
  split($3,prs,/\//);
  gsub(/A:/,"",prs[2]);
  gsub(/C:/,"",prs[4]);
  gsub(/-/,"_",prs[4]);
  gsub(/+/,"_",prs[4]);
  split(prs[2], aa, /_/); # <- accent information(A:)
  ncc = split(prs[4], cc, /_/); # <- accent information(C:)
  gsub(/Q:/,"",prs[7]); # <- Question or not
  if ( 0 ){
#    print prs[2], prs[4], ncc;
      printf("%s %s ", aa[1], aa[2]);
      for(i=1;i<=ncc;i++){
	  printf("%s ", cc[i]);
      }
#    printf("\n");
  }
  #if( aa[2] == "0" ){
  #printf("%s%s\n", ph[3], "'");
  #}
  
  #adding L, H symbols
  symbol_LH = "";
  if (cc[6]== 0){
      if(aa[1]== 1) symbol_LH= "L";
      else symbol_LH= "H";
  }else if (cc[6]== 1){
      if(aa[1]== 1) symbol_LH= "H";
      else symbol_LH= "L";
  }else{
      if(aa[1]== 1) symbol_LH= "L";
      else if(2<= aa[1]&& aa[1]<=cc[6]) symbol_LH= "H";
      else symbol_LH= "L";
  }

  if( (prs[7] == "1") && ((aa[1]!="x") && (aa[1]==cc[5])) ){
      printf("%s%s%s\n", ph[3], "?", symbol_LH);
  }
  else if( (cc[13] == "1") && ((aa[1]!="x") && (aa[1]==cc[5])) ){
      printf("%s%s%s\n", ph[3], "/", symbol_LH);
  }
  else{
      if (ph[3]=="sil" || ph[3]=="pau")printf("%s\n", ph[3]);
      else printf("%s%s\n", ph[3], symbol_LH);
  }
  if ( 0 ){
      acc[1] = (aa[1]=="x")?0:((aa[1]-1)/10);
      acc[2] = (aa[1]=="x")?0:(aa[2]/10);
      acc[3] = (aa[1]=="x")?0:((cc[5]-aa[1])/10);
      acc[4] = (aa[1]=="x")?0:1;
      
      acc[5] = (cc[4]=="x")?0:(cc[1]/10);
      acc[6] = (cc[4]=="x")?0:(cc[2]/10);
      acc[7] = (cc[4]!="x" && cc[2]==0)?1:0;
      acc[8] = (cc[4]=="x")?0:(cc[4]);
      acc[9] = (cc[4]=="x")?0:1;
      
      acc[10] = (cc[9]=="x")?0:(cc[5]/10);
      acc[11] = (cc[9]=="x")?0:(cc[6]/10);
      acc[12] = (cc[9]!="x" && cc[6]==0)?1:0;
      acc[13] = (cc[9]=="x")?0:(cc[9]/10);
      acc[14] = (cc[9]=="x")?0:(($4-cc[9])/10);
      acc[15] = (cc[9]=="x")?0:(($4-1)/5);
      acc[16] = (cc[9]=="x")?0:1;
      
      acc[17] = (cc[13]=="x")?0:(cc[10]/10);
      acc[18] = (cc[13]=="x")?0:(cc[11]/10);
      acc[19] = (cc[13]!="x" && cc[11]==0)?1:0;
      acc[20] = (cc[13]=="x")?0:(cc[13]);
      acc[21] = (cc[13]=="x")?0:1;
      
      acc[22] = (prs[7]=="x")?0:(prs[7]);
      
      acc[23] = ((acc[1]!=acc[8]) || (acc[1]==0))?0:1;
      
      
      if ( 1 ){
	  
# extract duration info.
	  sum = 0;
	  
# output parameters for DNN
	  for(k=1;k<=5;k++){
	      for(l=1;l<=phsize;l++){
		  printf("%d ", phbin[k,l]);
	      }
	  }
	  for(nc=1;nc<=23;nc++){
	      printf("%f ", acc[nc]);
	  }
	  printf("\n");
      }
  }
}

END{
    
}
