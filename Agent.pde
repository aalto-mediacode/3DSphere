class Agent {
  PVector location;
  PVector velocity;
  PVector acceleration;
  PVector target;
  
  float maxSpeed;
  float maxForce;
  float topVel = 6;
  
  float targetRange = 100;
  
  Agent(PVector target) {
    this.location = new PVector(0, 0, 0);
    this.velocity = new PVector(0, 0, 0);
    this.acceleration = new PVector(0, 0, 0);
    this.target = target;

    this.maxSpeed = this.maxForce = random(0.05, this.topVel);
  }
  
  void show() {
    strokeWeight(2);
    stroke(255);
    point(this.location.x, this.location.y, this.location.z);
  }
  
  void anim() {
    this.velocity.add(this.acceleration);
    this.velocity.limit(this.maxSpeed);
    this.location.add(this.velocity);
    this.acceleration.mult(0);
  }
  
  
  void seek() {
    PVector desired = PVector.sub(this.target, this.location);
    
    float d = desired.mag();

    if (d < 100) {
      float m = map(d, 0, this.targetRange, 0.05, this.maxSpeed);
      desired.setMag(m);
    } else {
      desired.setMag(maxSpeed);
    }
    
    PVector steer = PVector.sub(desired, this.velocity);
    steer.limit(this.maxForce);
    
    this.applyForce(steer);
  }
  
  void applyForce(PVector force) {
    this.acceleration.add(force);
  }
  
}