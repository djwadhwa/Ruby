# CSE341, Programming Languages, Homework 7, hw7.rb (see also SML code)

# a little language for 2D geometry objects

# each subclass of GeometryExpression, including subclasses of GeometryValue,
#  needs to respond to messages preprocess_prog and eval_prog
#
# each subclass of GeometryValue additionally needs:
#   * shift
#   * intersect, which uses the double-dispatch pattern
#   * intersectPoint, intersectLine, and intersectVerticalLine for 
#       for being called by intersect of appropriate clases and doing
#       the correct intersection calculuation
#   * (We would need intersectNoPoints and intersectLineSegment, but these
#      are provided by GeometryValue and should not be overridden.)
#   *  intersectWithSegmentAsLineResult, which is used by 
#      intersectLineSegment as described in the assignment
#
# you can define other helper methods, but will not find much need to

# Note: geometry objects should be immutable: assign to fields only during
#       object construction

# Note: For eval_prog, represent environments as arrays of 2-element arrays
# as described in the assignment

class GeometryExpression  
  # do *not* change this class definition
  Epsilon = 0.00001
end

class GeometryValue 
  # do *not* change methods in this class definition
  # you can add methods if you wish

  private
  # some helper methods that may be generally useful
  def real_close(r1,r2) 
      (r1 - r2).abs < GeometryExpression::Epsilon
  end
  def real_close_point(x1,y1,x2,y2) 
      real_close(x1,x2) && real_close(y1,y2)
  end
  # two_points_to_line could return a Line or a VerticalLine
  def two_points_to_line(x1,y1,x2,y2) 
      if real_close(x1,x2)
        VerticalLine.new x1
      else
        m = (y1 - y2).to_f / (x1 - x2)
        b = y2 - m * x2
        Line.new(m,b)
      end
  end

  public
  # we put this in this class so all subclasses can inherit it:
  # the intersection of self with a NoPoints is a NoPoints object
  def intersectNoPoints np
    np # could also have NoPoints.new here instead
  end

  # we put this in this class so all subclasses can inhert it:
  # the intersection of self with a LineSegment is computed by
  # first intersecting with the line containing the segment and then
  # calling the result's intersectWithSegmentAsLineResult with the segment
  def intersectLineSegment seg
    line_result = intersect(two_points_to_line(seg.x1,seg.y1,seg.x2,seg.y2))
    line_result.intersectWithSegmentAsLineResult seg
  end
end

class NoPoints < GeometryValue
  # do *not* change this class definition: everything is done for you
  # (although this is the easiest class, it shows what methods every subclass
  # of geometry values needs)

  # Note: no initialize method only because there is nothing it needs to do
  def eval_prog env 
    self # all values evaluate to self
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx,dy)
    self # shifting no-points is no-points
  end
  def intersect other
    other.intersectNoPoints self # will be NoPoints but follow double-dispatch
  end
  def intersectPoint p
    self # intersection with point and no-points is no-points
  end
  def intersectLine line
    self # intersection with line and no-points is no-points
  end
  def intersectVerticalLine vline
    self # intersection with line and no-points is no-points
  end
  # if self is the intersection of (1) some shape s and (2) 
  # the line containing seg, then we return the intersection of the 
  # shape s and the seg.  seg is an instance of LineSegment
  def intersectWithSegmentAsLineResult seg
    self
  end
end


class Point < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods

  # Note: You may want a private helper method like the local
  # helper function inbetween in the ML code
  attr_reader :x, :y
  def initialize(x,y)
    @x = x
    @y = y
  end
  def eval_prog env 
    self 
  end
  def preprocess_prog
    self # no pre-processing to do here
  end
  def shift(dx,dy)
    Point.new(self.x+dx, self.y+dy)
  end
  def intersect other
    other.intersectPoint self
  end
  def intersectPoint p
    if real_close_point(self.x, self.y, p.x, p.y)
    then p
    else NoPoints.new()
    end
  end
  def intersectLine line
    if real_close(self.y, (line.m * self.x) + line.b)
    then self
    else NoPoints.new()
    end
  end
  def intersectVerticalLine vline
    if real_close(self.x, vline.x)
    then self
    else NoPoints.new()
    end
  end
  def intersectWithSegmentAsLineResult seg
    if (inbetween(self.x,seg.x1,seg.x2) and inbetween(self.y,seg.y1,seg.y2))
    then self
    else NoPoints.new()
    end
  end
  private
  def inbetween (v, end1, end2)
    (end1 - GeometryExpression::Epsilon <= v and v<= end2 + GeometryExpression::Epsilon) or
      (end2 - GeometryExpression::Epsilon <= v and v <= end1 + GeometryExpression::Epsilon)
  end
end

class Line < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :m, :b 
  def initialize(m,b)
    @m = m
    @b = b
  end
  def eval_prog env 
    self
  end
  def preprocess_prog
    self 
  end
  def shift(dx,dy)
    Line.new(self.m, self.b+dy - self.m*dx)
  end
  def intersect other
    other.intersectLine self
  end
  def intersectPoint p
    p.intersectLine self
  end
  def intersectLine line
    if real_close(line.m, self.m)
    then (if real_close(line.b,self.b)
         then self
         else NoPoints.new()
          end)
    else
      (x = (self.b-line.b)/(line.m-self.m)
       y = (line.m * x + line.b)
       Point.new(x,y))
    end
  end
  def intersectVerticalLine vline
    Point.new(vline.x, self.m * vline.x + self.b)
  end
  def intersectWithSegmentAsLineResult seg
    seg
  end
end

class VerticalLine < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  attr_reader :x
  def initialize x
    @x = x
  end
  def eval_prog env 
    self
  end
  def preprocess_prog
    self 
  end
  def shift(dx,dy)
    VerticalLine.new(self.x+dx)
  end
  def intersect other
    other.intersectVerticalLine self
  end
  def intersectPoint p
    p.intersectVerticalLine self
  end
  def intersectLine line
    line.intersectVerticalLine self
  end
  def intersectVerticalLine vline
    if real_close(vline.x, self.x)
    then self
    else NoPoints.new()
    end
  end
  def intersectWithSegmentAsLineResult seg
    seg
  end
end

class LineSegment < GeometryValue
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: This is the most difficult class.  In the sample solution,
  #  preprocess_prog is about 15 lines long and 
  # intersectWithSegmentAsLineResult is about 40 lines long
  # remember (x1,y1) is to the /right/ of (x2,y2) or /above/ if x1 is real
  # close to x2
  attr_reader :x1, :y1, :x2, :y2
  def initialize (x1,y1,x2,y2)
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
  end
  def eval_prog env 
    self 
  end
  def preprocess_prog
    if (real_close_point(self.x1,self.y1,self.x2,self.y2))
      Point.new(self.x1,self.y1)
    else
      if (real_close(self.x1, self.x2))
        if (self.y2>self.y1)
          LineSegment.new(self.x2,self.y2,self.x1,self.y1)
        else self
        end
      else
        if (self.x2 > self.x1)
          LineSegment.new(self.x2,self.y2,self.x1,self.y1)
        else self
        end
      end
    end
  end
  def shift(dx,dy)
    LineSegment.new(self.x1+dx,self.y1+dy,self.x2+dx,self.y2+dy)
  end
  def intersect other
    other.intersectLineSegment self
  end
  def intersectWithSegmentAsLineResult seg
    if real_close(seg.x2,seg.x1)
    then #segments on vertical line
      (if (seg.y2 < self.y2)
      then ifVerticalLine [seg, self]
      else ifVerticalLine [self,seg]
       end)
    else #segments on non-vertical line
      (if (seg.x2 < self.x2)
      then ifNotVerticalLine [seg, self]
      else ifNotVerticalLine [self,seg]
       end)
    end
  end
  def intersectLine line
    line.intersectLineSegment self
  end
  def intersectPoint p
    p.intersectLineSegment self
  end
  def intersectVerticalLine vline
    vline.intersectLineSegment self
  end
  
  private
  def ifVerticalLine v
    if real_close(v[0].y1, v[1].y2)
      then Point.new(v[0].x1,v[0].y1)
      elsif v[0].y1 < v[1].y2
      then NoPoints.new()
      elsif v[0].y1 > v[1].y1
      then LineSegment.new(v[1].x1,v[1].y1,v[1].x2,v[1].y2)
      else LineSegment.new(v[0].x1,v[0].y1,v[1].x2,v[1].y2)
    end
  end
  def ifNotVerticalLine v
    if real_close(v[0].x1,v[1].x2)
    then Point.new(v[0].x1,v[0].y1)
    elsif v[0].x1 < v[1].x2
    then NoPoints.new()
    elsif v[0].x1 > v[1].x1
    then LineSegment.new(v[1].x1,v[1].y1,v[1].x2,v[1].y2)
    else LineSegment.new(v[0].x1,v[0].y1,v[1].x2,v[1].y2)
    end
  end
end
# Note: there is no need for getter methods for the non-value classes

class Intersect < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(e1,e2)
    @e1 = e1
    @e2 = e2
  end
  def preprocess_prog
    Intersect.new(@e1.preprocess_prog, @e2.preprocess_prog)
  end
  def eval_prog env
    (@e1.eval_prog env).intersect(@e2.eval_prog env)
  end
end

class Let < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  # Note: Look at Var to guide how you implement Let
  def initialize(s,e1,e2)
    @s = s
    @e1 = e1
    @e2 = e2
  end
  def preprocess_prog
    Let.new(@s, @e1.preprocess_prog, @e2.preprocess_prog)
  end
  def eval_prog env
    newenv = [[@s,(@e1.eval_prog env)]] + env.clone 
    @e2.eval_prog newenv
  end
    
end

class Var < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize s
    @s = s
  end
  def eval_prog env # remember: do not change this method
    pr = env.assoc @s
    raise "undefined variable" if pr.nil?
    pr[1]
  end
  def preprocess_prog
    self
  end
end

class Shift < GeometryExpression
  # *add* methods to this class -- do *not* change given code and do not
  # override any methods
  def initialize(dx,dy,e)
    @dx = dx
    @dy = dy
    @e = e
  end
  def preprocess_prog
    Shift.new(@dx,@dy,@e.preprocess_prog)
  end
  def eval_prog env
    (@e.eval_prog env).shift(@dx,@dy)
  end
end

