// imports
import ddf.minim.*;
import netP5.*;
import oscP5.*;
import codeanticode.syphon.*;
import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;

// osc config
OscP5 oscP5;
NetAddress myRemoteLocation;

// syphon config
SyphonServer server;

// postfx config
PostFX fx;
Aberration aberration;

// minim config
Minim minim;
AudioInput in;

// global variables
int total = 64;
float r = 200;
float zoom = -1000;
float zoomSpeed = 0.2;
float rotation = 0;
float scatter = 2500;
int listen = -1;
int lines = -1;

Agent a;

int numAgents = total * total;
Agent[] agents = new Agent[numAgents];

PVector[] circleLocations = new PVector[numAgents];

void setup() {
  size(1920, 1080, P3D);
  
  // syphon setup
  server = new SyphonServer(this, "3D Sphere");
  
  // postfx setup
  fx = new PostFX(this);
  aberration = new Aberration();
  
  // osc setup
  oscP5 = new OscP5(this, 7001);
  myRemoteLocation = new NetAddress("localhost", 7000);
  
  // minim setup
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 4096);
  
  // create a sphere of agents
  int index = 0;
  
  for (int i = 0; i < total; i++) {
    float lon = map(i, 0, total, -PI, PI);
    for (int j = 0; j < total; j++) {
      float lat = map(j, 0, total, -HALF_PI, HALF_PI);
      float x = r * sin(lon) * cos(lat);
      float y = r * sin(lon) * sin(lat);
      float z = r * cos(lon);

      PVector target = new PVector(x, y, z);
      
      agents[index] = new Agent(target);
      
      circleLocations[index] = new PVector(x, y, z);
      
      index++;
    }
  }
}

void draw() {
  translate(width / 2, height / 2, zoom);
  rotateX(rotation);
  rotateY(rotation);
  rotateZ(rotation);

  background(0);
  noStroke();

  for (int i = 0; i < numAgents; i++) {
    
    if (listen > 0) {
      PVector amp = agents[i].velocity.mult(in.mix.get(i) * 200);
      agents[i].applyForce(amp);
    }

    if (i > 0 && lines > 0) {
      float d = dist(
        agents[i].location.x,
        agents[i].location.y,
        agents[i].location.z,
        agents[i - 1].location.x,
        agents[i - 1].location.y,
        agents[i - 1].location.z
      );
      
      if (d < 60) {
        stroke(255);
        strokeWeight(1);
        line(
          agents[i].location.x,
          agents[i].location.y,
          agents[i].location.z,
          agents[i - 1].location.x,
          agents[i - 1].location.y,
          agents[i - 1].location.z
        );
      }
    }

    agents[i].seek();
    agents[i].anim();
    agents[i].show();
  }

  // rotation and zoom
  rotation += 0.001;
  zoom += zoomSpeed;
  
  // add post fx
  fx.render()
  .custom(aberration)
  .compose();
  
  // send screen to Resolume
  server.sendScreen();
}

// osc input
void oscEvent(OscMessage theOscMessage) {
  
  // gather sphere
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/1/select") == true) {
    for (int i = 0; i < numAgents; i++) {
      agents[i].target.set(circleLocations[i]);
    }
  }
  
  // explosion
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/2/select") == true) {
    for (int i = 0; i < numAgents; i++) {
      agents[i].target.set(random(-scatter, scatter), random(-scatter, scatter), random(-scatter, scatter));
    }
  }
  
  // reverse sphere
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/3/select") == true) {
    for (int i = 0; i < numAgents; i++) {
      agents[i].target.set(circleLocations[(numAgents - 1) - i]);
    }
  }
  
  // twitch
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/4/select") == true) {
    for (int i = 0; i < numAgents; i++) {
      PVector twitch = new PVector(random(-10, 10), random(-10, 10), random(-10, 10));
      agents[i].velocity.set(twitch);
    }
  }
  
  // agent amplitude
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/5/select") == true) {
   listen *= -1;
  }
  
  // lines
  if (theOscMessage.checkAddrPattern("/composition/layers/1/clips/6/select") == true) {
   lines *= -1;
  }
  
  // agent speed
  if (theOscMessage.checkAddrPattern("/composition/dashboard/link1") == true) {
    for (int i = 0; i < numAgents; i++) {
      agents[i].maxSpeed = map(theOscMessage.get(0).floatValue(), 0, 1, 0.1, 8);
    }
  }
  
  // zoomspeed
  if (theOscMessage.checkAddrPattern("/composition/dashboard/link2") == true) {
    zoomSpeed = map(theOscMessage.get(0).floatValue(), 0, 1, -3, 3);
  }
}