
class Animazioni {
  int firstFrame=0;
  int lastFrame=0;
  int startLoop=0;
  int durationfirstpart=0;
  int durationloop=0;

  Animazioni(int firstFrame, int lastFrame, int startLoop, int durationfirstpart, int durationloop){
    this.firstFrame=firstFrame;
    this.lastFrame=lastFrame;
    this.startLoop=startLoop;
    this.durationfirstpart=durationfirstpart;
    this.durationloop=durationloop;
  }
  
  SetDurationLoop(int durationloop){
    this.durationloop=durationloop;
  }
  SetDurationFirstPart(int durationfirstpart){
    this.durationfirstpart=durationfirstpart;
  }



}