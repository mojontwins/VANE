#include <windows.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>


unsigned int RdWordLH(unsigned char *bytes)
{
	unsigned int num;
	
	num=*bytes++;
	num|=*bytes++<<8;
	
	return num;
}



unsigned int RdDWordLH(unsigned char *bytes)
{
	unsigned int num;
	
	num=*bytes++;
	num|=*bytes++<<8;
	num|=*bytes++<<16;
	num|=*bytes++<<24;
	
	return num;
}



int main(int argc, char* argv[])
{
	const int outrate=16000;
	FILE *file;
	char wname[MAX_PATH],oname[MAX_PATH];
	unsigned char *wave,*snd;
	int aa,bb,len,fsize,rate,samples,channels;
	int bits,ptr,size,smp1,smp2,pp,pd,smpsize,ioff;
	float off,step,outsmp;
	bool fl;
	
	printf("wav2snd v1.02 by Shiru 27.04.07\n\n");
	
	if(argc<=1)
	{
		printf("USAGE: wav2snd filename.wav (output will be same filename.snd)\n");
		return 0;
	}
	
	strcpy(wname,argv[1]);
	strcpy(oname,wname);
	len=strlen(wname);
	for(aa=len-1;aa>0;aa--)
	{
		if(oname[aa]=='.') { oname[aa]=0; break; }
	}
	strcat(oname,".raw");
	
	file=fopen(wname,"rb");
	if(!file)
	{
		printf("ERR: File '%s' not found.\n",wname);
		return 1;
	}
	
	
	fseek(file,0,SEEK_END);
	fsize=ftell(file);
	fseek(file,0,SEEK_SET);
	
	wave=(unsigned char*)malloc(fsize);
	if(!wave)
	{
		printf("ERR: Can`t allocate memory.\n");
		return 1;
	}
	memset(wave,0,fsize);
	fread(wave,fsize,1,file);
	fclose(file);
	
	fl=false;
	for(aa=0;aa<fsize-4;aa++)
	{
		if(memcmp(&wave[aa],"RIFF",4)==0)
		{
			fl=true;
			ptr=aa;
			break;
		}
	}
	if(!fl)
	{
		printf("ERR: RIFF chunk not found.\n");
		free(wave);
		return 1;
	}
	fl=false;
	for(aa=ptr;aa<fsize-4;aa++)
	{
		if(!memcmp(&wave[aa],"WAVEfmt ",8))
		{
			fl=true;
			ptr=aa;
			break;
		}
	}
	if(!fl)
	{
		printf("ERR: WAVEfmt chunk not found.\n");
		free(wave);
		return 1;
	}
	if(RdWordLH(&wave[ptr+12])!=1)
	{
		printf("ERR: Only unpacked PCM supported.\n");
		free(wave);
		return 1;
	}
	channels=RdWordLH(&wave[ptr+14]);
	if(channels<1||channels>2)
	{
		printf("ERR: Only mono/stereo files supported.\n");
		free(wave);
		return 1;
	}
	rate=RdDWordLH(&wave[ptr+16]);
	bits=RdWordLH(&wave[ptr+26]);
	if(bits!=8&&bits!=16)
	{
		printf("ERR: Only 8/16bit PCM supported.\n");
		free(wave);
		return 1;
	}
	fl=false;
	for(aa=ptr+28;aa<fsize-4;aa++)
	{
		if(!memcmp(&wave[aa],"data",4))
		{
			fl=true;
			ptr=aa;
			break;
		}
	}
	if(!fl)
	{
		printf("ERR: DATA chunk not found.\n");
		free(wave);
		return 1;
	}
	
	samples=RdDWordLH(&wave[ptr+4])/channels/(bits>>3);
	
	printf("OK:  File '%s' opened successfully [PCM, %i Hz, %i channel(s), %i bit per sample, %i samples]\n",wname,rate,channels,bits,samples);
	
	ptr+=8;
	
	
	size=(int)(float(samples)/float(rate)*float(outrate));
	size=((size>>8)+1)<<8;//make length 256-byte aligned
	
	snd=(unsigned char*)malloc(size);
	
	off=0;
	pd=0;
	step=float(rate)/float(outrate);	
	smpsize=channels*(bits>>3);
	
	for(aa=0;aa<size;aa++)
	{
		ioff=int(off);
		if(ioff>=samples) ioff=samples-1;
		pp=ptr+ioff*smpsize;
		
		smp1=0;
		for(bb=0;bb<channels;bb++)
		{
			switch(bits)
			{
			case 8:
				smp1+=(signed char)(wave[pp]+128);
				pp++;
				break;
			case 16:
				smp1+=((signed char)wave[pp+1]);
				pp+=2;
				break;
			}
		}
		smp1=smp1/channels;
		
		ioff=int(off)+1;
		if(ioff>=samples) ioff=samples-1;
		pp=ptr+ioff*smpsize;
		
		smp2=0;
		for(bb=0;bb<channels;bb++)
		{
			switch(bits)
			{
			case 8:
				smp2+=(signed char)(wave[pp]+128);
				pp++;
				break;
			case 16:
				smp2+=((signed char)wave[pp+1]);
				pp+=2;
				break;
			}
		}
		smp2=smp2/channels;
		
		outsmp=float(smp1)*(off-floorf(off))+float(smp2)*(1.0f-(off-floorf(off)));
		
		snd[pd++]=(((int)outsmp)/4);
		
		off+=step;
	}
	
	free(wave);
	
	file=fopen(oname,"wb");
	if(!file)
	{
		printf("ERR: Can't create output file\n");
		free(snd);
		return 1;
	}
	fwrite(snd,size,1,file);
	fclose(file);
	free(snd);
	
	return 0;
}

