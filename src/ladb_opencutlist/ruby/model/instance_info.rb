module Ladb::OpenCutList

  require_relative '../utils/path_utils'

  class InstanceInfo

    attr_accessor :size
    attr_reader :path, :x_faces, :y_faces, :z_faces

    @size
    @x_faces
    @y_faces
    @z_faces

    def initialize(path = [], x_faces = [], y_faces = [], z_faces = [])
      @path = path
      @x_faces = x_faces
      @y_faces = y_faces
      @z_faces = z_faces
    end

    # -----

    def entity
      @path.last
    end

    def serialized_path
      if @serialized_path
        return @serialized_path
      end
      @serialized_path = PathUtils.serialize_path(@path)
    end

    def transformation
      if @transformation
        return @transformation
      end
      @transformation = PathUtils.get_transformation(@path)
    end

    def scale
      if @scale
        return @scale
      end
      @scale = TransformationUtils::get_scale3d(transformation)
    end

    def faces_by_normal(normal)
      case normal
        when X_AXIS
          x_faces
        when Y_AXIS
          y_faces
        when Z_AXIS
          z_faces
        else
          []
      end
    end

    # -----

    def size
      if @size
        return @size
      end
      Size3d.new
    end

  end

end