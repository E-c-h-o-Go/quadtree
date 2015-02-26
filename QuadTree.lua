local QuadTree = {};

local MAX_LEVELS = 8;
local MAX_OBJECTS = 8;
local NW = 1;
local NE = 2;
local SW = 3;
local SE = 4;

function QuadTree.new(lvl, bounds)
    local self = {};

    local level = lvl;
    local bounds = bounds;
    local objects = {};
    local nodes;

    function self:clear()
        objects = {};
        nodes = nil;
    end

    function self:split()
        local nw = bounds.w * 0.5;
        local nh = bounds.h * 0.5;
        local nx = bounds.x;
        local ny = bounds.y;

        nodes = {};
        nodes[NW] = QuadTree.new(level + 1, { x = nx, y = ny, w = nw, h = nh });
        nodes[NE] = QuadTree.new(level + 1, { x = nx + nw, y = ny, w = nw, h = nh });
        nodes[SW] = QuadTree.new(level + 1, { x = nx, y = ny + nh, w = nw, h = nh });
        nodes[SE] = QuadTree.new(level + 1, { x = nx + nw, y = ny + nh, w = nw, h = nh });
    end

    function self:draw()
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.w, bounds.h);
        love.graphics.print(#objects == 0 and '' or #objects, bounds.x + 1, bounds.y + 1);
        if nodes then
            for i = 1, #nodes do
                nodes[i]:draw();
            end
        end
        for i = 1, #objects do
            love.graphics.setColor(255, 0, 0);
            love.graphics.circle('fill', objects[i][1], objects[i][2], 2, 20);
            love.graphics.setColor(255, 255, 255);
        end
    end

    function self:getIndex(nx, ny)
        local midX = bounds.x + (bounds.w * 0.5);
        local midY = bounds.y + (bounds.h * 0.5);

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

    function self:insert(nx, ny)
        -- If the node is already split add it to one of its children.
        if nodes then
            local index = self:getIndex(nx, ny);
            nodes[index]:insert(nx, ny);
            return;
        end

        objects[#objects + 1] = { nx, ny };

        -- If the current node is not yet split and carries the maximum
        -- amount of objects, split it and redistribute the children.
        if #objects > MAX_OBJECTS then
            if level < MAX_LEVELS then
                self:split();

                for i = 1, #objects do
                    local index = self:getIndex(objects[i][1], objects[i][2]);
                    nodes[index]:insert(objects[i][1], objects[i][2]);
                end
                objects = {};
            end
        end
    end

    function self:retrieve(nx, ny)
        if nodes then
            local index = self:getIndex(nx, ny);
            return nodes[index]:retrieve(nx, ny);
        else
            return objects, bounds;
        end
    end

    return self;
end

return QuadTree;