module Ladb::OpenCutList

  class DrawingDef

    attr_reader :faces_bounds, :edges_bounds, :bounds, :face_manipulators, :surface_manipulators, :edge_manipulators, :curve_manipulators
    attr_accessor :transformation, :picked_plane_manipulator, :picked_line_manipulator

    def initialize

      @transformation = Geom::Transformation.new

      @faces_bounds = Geom::BoundingBox.new
      @edges_bounds = Geom::BoundingBox.new
      @bounds = Geom::BoundingBox.new

      @face_manipulators = []
      @surface_manipulators = []
      @edge_manipulators = []
      @curve_manipulators = []

      @picked_plane_manipulator = nil
      @picked_line_manipulator = nil

    end

    # -----

    def translate_to!(point)
      t = Geom::Transformation.translation(Geom::Vector3d.new(point.to_a))
      unless t.identity?

        ti = t.inverse

        @transformation *= t
        @picked_plane_manipulator.transformation = ti * @picked_plane_manipulator.transformation unless @picked_plane_manipulator.nil?
        @picked_line_manipulator.transformation = ti * @picked_line_manipulator.transformation unless @picked_line_manipulator.nil?

        unless @faces_bounds.empty?
          min = @faces_bounds.min.transform(ti)
          max = @faces_bounds.max.transform(ti)
          @faces_bounds.clear
          @faces_bounds.add(min, max)
        end

        unless @edges_bounds.empty?
          min = @edges_bounds.min.transform(ti)
          max = @edges_bounds.max.transform(ti)
          @edges_bounds.clear
          @edges_bounds.add(min, max)
        end

        unless @bounds.empty?
          min = @bounds.min.transform(ti)
          max = @bounds.max.transform(ti)
          @bounds.clear
          @bounds.add(min, max)
        end

        @face_manipulators.each do |face_manipulator|
          face_manipulator.transformation = ti * face_manipulator.transformation
        end
        @surface_manipulators.each do |surface_manipulator|
          surface_manipulator.transformation = ti * surface_manipulator.transformation
        end

        @edge_manipulators.each do |edge_manipulator|
          edge_manipulator.transformation = ti * edge_manipulator.transformation
        end
        @curve_manipulators.each do |curve_manipulator|
          curve_manipulator.transformation = ti * curve_manipulator.transformation
        end

      end

    end

  end

end