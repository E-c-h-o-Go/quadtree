local QuadTree = {};

local MAX_LEVELS = 5;
local MAX_OBJECTS = 8;
local NW = 1;
local NE = 2;
local SW = 3;
local SE = 4;

function QuadTree.new(lvl, x, y, w, h)
    local self = {};

    local level = lvl;
    local midX = x + (w * 0.5);
    local midY = y + (h * 0.5);
    local objects = {};
    local nodes;

    local function determineIndex(nx, ny)
        -- Check if the object fits in one of the four quadrants.
        if nx <= midX and ny <= midY then
            -- top left
            return NW;
        elseif nx <= midX and ny > midY then
            -- bottom left
            return SW;
        elseif nx > midX and ny <= midY then
            -- top right
            return NE;
        elseif nx > midX and ny > midY then
            -- bottom right
            return SE;
        end
    end

    function self:clear()
        objects = {};
        nodes = nil;
    end

    function self:split()
        local nw = w * 0.5;
        local nh = h * 0.5;
        local nx = x;
        local ny = y;

        nodes = {};
        nodes[NW] = QuadTree.new(level + 1, nx, ny, nw, nh);
        nodes[NE] = QuadTree.new(level + 1, nx + nw, ny, nw, nh);
        nodes[SW] = QuadTree.new(level + 1, nx, ny + nh, nw, nh);
        nodes[SE] = QuadTree.new(level + 1, nx + nw, ny + nh, nw, nh);
    end

    function self:draw()
        love.graphics.rectangle('line', x, y, w, h);
        love.graphics.print(#objects == 0 and '' or #objects, x + 1, y + 1);
        if nodes then
            for i = 1, #nodes do
                nodes[i]:draw();
            end
        end
    end

    function self:insert(obj, nx, ny)
        -- If the node is already split add it to one of its children.
        if nodes then
            local index = determineIndex(nx, ny);
            nodes[index]:insert(obj, nx, ny);
            return;
        end

        objects[#objects + 1] = obj;

        -- If the current node is not yet split and carries the maximum
        -- amount of objects, split it and redistribute the children.
        if #objects > MAX_OBJECTS then
            if level < MAX_LEVELS then
                self:split();

                for i = 1, #objects do
                    local index = determineIndex(objects[i]:getX(), objects[i]:getY());
                    nodes[index]:insert(objects[i], objects[i]:getX(), objects[i]:getY());
                end
                objects = {};
            end
        end
    end

    function self:retrieve(nx, ny)
        if nodes then
            local index = determineIndex(nx, ny);
            return nodes[index]:retrieve(nx, ny);
        else
            return objects;
        end
    end

    return self;
end

return QuadTree;