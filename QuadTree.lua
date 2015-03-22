--==================================================================================================
-- Copyright (C) 2015 by Robert Machmer                                                            =
--                                                                                                 =
-- Permission is hereby granted, free of charge, to any person obtaining a copy                    =
-- of this software and associated documentation files (the "Software"), to deal                   =
-- in the Software without restriction, including without limitation the rights                    =
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell                       =
-- copies of the Software, and to permit persons to whom the Software is                           =
-- furnished to do so, subject to the following conditions:                                        =
--                                                                                                 =
-- The above copyright notice and this permission notice shall be included in                      =
-- all copies or substantial portions of the Software.                                             =
--                                                                                                 =
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                      =
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                        =
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                     =
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                          =
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                   =
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                       =
-- THE SOFTWARE.                                                                                   =
--==================================================================================================

local QuadTree = {};

-- ------------------------------------------------
-- Constants
-- ------------------------------------------------

local MAX_LEVELS = 5;
local MAX_OBJECTS = 8;
local NW = 1;
local NE = 2;
local SW = 3;
local SE = 4;

-- ------------------------------------------------
-- Constructor
-- ------------------------------------------------

function QuadTree.new(lvl, x, y, w, h)
    local self = {};

    local level = lvl;
    local midX = x + (w * 0.5);
    local midY = y + (h * 0.5);
    local objects = {};

    local split = false;
    local nodes;

    -- ------------------------------------------------
    -- Private Functions
    -- ------------------------------------------------

    ---
    -- Determines in which subnode the given coordinates are
    -- contained and returns the corresponding index.
    -- @param nx
    -- @param ny
    --
    local function determineIndex(nx, ny)
        if nx <= midX and ny <= midY then
            return NW;
        elseif nx <= midX and ny > midY then
            return SW;
        elseif nx > midX and ny <= midY then
            return NE;
        elseif nx > midX and ny > midY then
            return SE;
        end
    end

    ----
    -- Divides the current node and creates four subnodes
    -- if they haven't been created yet.
    --
    local function divide()
        local nw = w * 0.5;
        local nh = h * 0.5;
        local nx = x;
        local ny = y;

        if not nodes then
            nodes = {};
            nodes[NW] = QuadTree.new(level + 1, nx, ny, nw, nh);
            nodes[NE] = QuadTree.new(level + 1, nx + nw, ny, nw, nh);
            nodes[SW] = QuadTree.new(level + 1, nx, ny + nh, nw, nh);
            nodes[SE] = QuadTree.new(level + 1, nx + nw, ny + nh, nw, nh);
        end
        split = true;
    end

    -- ------------------------------------------------
    -- Public Functions
    -- ------------------------------------------------

    ---
    -- Draws the quadtree for debug purposes. Can have a negative
    -- impact on FPS so use with caution.
    --
    function self:debugDraw()
        love.graphics.rectangle('line', x, y, w, h);
        love.graphics.print(#objects == 0 and '' or #objects, x + 1, y + 1);
        if split then
            for i = 1, #nodes do
                nodes[i]:debugDraw();
            end
        end
    end

    ---
    -- Clears all references to objects stored in the node.
    --
    function self:clear()
        if split then
            for i = 1, #nodes do
                nodes[i]:clear();
            end
            split = false;
        else
            for i = 1, #objects do
                objects[i] = nil;
            end
        end
    end

    ---
    -- Inserts a new object into the node. If the node is already split,
    -- the object is pushed to one of the subnodes. If it hasn't been split
    -- yet the object will be added to the current level. The node is split,
    -- when the amount of objects is bigger than the maximum of allowed
    -- nodes.
    -- @param obj
    -- @param nx
    -- @param ny
    --
    function self:insert(obj, nx, ny)
        -- If the node is already split add it to one of its children.
        if split then
            nodes[determineIndex(nx, ny)]:insert(obj, nx, ny);
            return;
        end

        -- If the node isn't split add the object to its pool.
        objects[#objects + 1] = obj;

        -- If the amount of objects surpasses the maximum amount allowed,
        -- the node is split and the objects are redistributed among the
        -- subnodes.
        if #objects > MAX_OBJECTS then
            if level < MAX_LEVELS then
                divide();

                local ox, oy;
                for i = 1, #objects do
                    ox, oy = objects[i]:getPosition();
                    nodes[determineIndex(ox, oy)]:insert(objects[i], ox, oy);
                    objects[i] = nil;
                end
            end
        end
    end

    ---
    -- Retrieves all objects in the same node as the given coordinates.
    -- @param nx
    -- @param ny
    --
    function self:retrieve(nx, ny)
        if split then
            return nodes[determineIndex(nx, ny)]:retrieve(nx, ny);
        end
        return objects;
    end

    return self;
end

return QuadTree;