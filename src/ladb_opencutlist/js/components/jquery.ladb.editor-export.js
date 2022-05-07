+function ($) {
    'use strict';

    // CLASS DEFINITION
    // ======================

    var LadbEditorExport = function (element, options) {
        this.options = options;
        this.$element = $(element);

        this.variableDefs = [];

        this.$editingItem = null;
        this.$editingForm = null;
    };

    LadbEditorExport.DEFAULTS = {
        vars: []
    };

    LadbEditorExport.prototype.setColDefs = function (colDefs) {
        var that = this;

        // Cancel editing
        this.editColumn(null);

        // Populate rows
        this.$sortable.empty();
        $.each(colDefs, function (index, colDef) {

            // Append column
            that.appendColumnItem(false, colDef.name, colDef.header, colDef.formula, colDef.align, colDef.hidden);

        });

    };

    LadbEditorExport.prototype.getColDefs = function () {
        var colDefs = [];
        this.$sortable.children('li').each(function () {
            colDefs.push({
                name: $(this).data('name'),
                header: $(this).data('header'),
                formula: $(this).data('formula'),
                align: $(this).data('align'),
                hidden: $(this).data('hidden')
            });
        });
        return colDefs;
    };

    LadbEditorExport.prototype.setEditingItemIndex = function (index) {
        var $item = $(this.$sortable.children().get(index));
        if ($item.length) {
            this.editColumn($item);
        }
    }

    LadbEditorExport.prototype.getEditingItemIndex = function () {
        return this.$editingItem ? this.$editingItem.index() : null;
    }

    LadbEditorExport.prototype.appendColumnItem = function (appendAfterEditingItem, name, header, formula, align, hidden) {
        var that = this;

        // Create and append row
        var $item = $(Twig.twig({ref: "tabs/cutlist/_export-column-item.twig"}).render({
            name: name || '',
            header: header || '',
            formula: formula || '',
            align: align || 'left',
            hidden: hidden || false
        }));
        if (appendAfterEditingItem && this.$editingItem) {
            this.$editingItem.after($item);
        } else {
            this.$sortable.append($item);
        }

        // Bind row
        $item.on('click', function () {
            that.editColumn($item);
            return false;
        })

        // Bind buttons
        $('a.ladb-cutlist-export-column-item-formula-btn', $item).on('click', function () {
            that.editColumn($item, 'formula');
            return false;
        });
        $('a.ladb-cutlist-export-column-item-align-btn', $item).on('click', function () {
            var $icon = $('i', $(this));
            var align = $item.data('align');
            $icon.removeClass('ladb-opencutlist-icon-align-' + align);
            switch (align) {
                case 'left':
                    align = 'center';
                    break;
                case 'center':
                    align = 'right';
                    break;
                case 'right':
                    align = 'left';
                    break;
            }
            $item.data('align', align);
            $icon.addClass('ladb-opencutlist-icon-align-' + align);
            return false;
        });
        $('a.ladb-cutlist-export-column-item-visibility-btn', $item).on('click', function () {
            var $icon = $('i', $(this));
            var hidden = $item.data('hidden');
            if (hidden === true) {
                hidden = false;
                $item.removeClass('ladb-inactive');
                $icon.removeClass('ladb-opencutlist-icon-eye-close');
                $icon.addClass('ladb-opencutlist-icon-eye-open');
            } else {
                hidden = true;
                $item.addClass('ladb-inactive');
                $icon.addClass('ladb-opencutlist-icon-eye-close');
                $icon.removeClass('ladb-opencutlist-icon-eye-open');
            }
            $item.data('hidden', hidden);
            return false;
        });

        return $item;
    };

    LadbEditorExport.prototype.editColumn = function ($item, focusTo) {
        var that = this;

        // Cleanup
        if (this.$editingForm) {
            this.$editingForm.remove();
        }
        if (this.$btnContainer) {
            this.$btnContainer.empty();
        }
        if (this.$editingItem) {
            this.$editingItem.removeClass('ladb-selected');
        }

        this.$editingItem = $item;
        if ($item) {

            // Mark item as selected
            this.$editingItem.addClass('ladb-selected');

            // Buttons
            var $btnRemove = $('<button class="btn btn-danger"><i class="ladb-opencutlist-icon-clear"></i> ' + i18next.t('tab.cutlist.export.remove_column') + '</button>');
            $btnRemove
                .on('click', function () {
                    that.removeColumn($item);
                })
            ;
            this.$btnContainer.append($btnRemove);

            // Create the form
            this.$editingForm = $(Twig.twig({ref: "tabs/cutlist/_export-column-form.twig"}).render({
                name: $item.data('name'),
                header: $item.data('header'),
                formula: $item.data('formula')
            }));

            var $inputHeader = $('#ladb_input_header', this.$editingForm);
            var $inputFormula = $('#ladb_div_formula', this.$editingForm);

            // Bind inputs
            $inputHeader
                .ladbTextinputText()
                .on('keyup', function () {
                    $item.data('header', $(this).val());

                    // Update item header
                    $('.ladb-cutlist-export-column-item-header', $item).replaceWith(Twig.twig({ref: "tabs/cutlist/_export-column-item-header.twig"}).render({
                        name: $item.data('name'),
                        header: $item.data('header')
                    }));

                })
            ;
            $inputFormula
                .ladbTextinputCode({
                    variableDefs: this.variableDefs
                })
                .on('change', function () {
                    $item.data('formula', $(this).val());

                    // Update item formula button
                    if ($(this).val() === '') {
                        $('.ladb-cutlist-export-column-item-formula-btn', $item).removeClass('ladb-active');
                    } else {
                        $('.ladb-cutlist-export-column-item-formula-btn', $item).addClass('ladb-active');
                    }

                })
            ;

            this.$element.append(this.$editingForm);

            // Focus
            if (focusTo === 'formula') {
                $inputFormula.focus();
            } else {
                $inputHeader.focus();
            }

            // Scroll to item
            if ($item.position().top < 0) {
                this.$sortable.animate({ scrollTop: this.$sortable.scrollTop() + $item.position().top }, 200);
            } else if ($item.position().top + $item.outerHeight() > this.$sortable.outerHeight(true)) {
                this.$sortable.animate({ scrollTop: this.$sortable.scrollTop() + $item.position().top + $item.outerHeight(true) - this.$sortable.outerHeight() }, 200);
            }

            if (this.$helpBlock) {
                this.$helpBlock.hide();
            }

        } else {

            if (this.$helpBlock) {
                this.$helpBlock.show();
            }

        }

    };

    LadbEditorExport.prototype.removeColumn = function ($item) {

        // Retrieve sibling item if possible
        var $siblingItem = $item.next();
        if ($siblingItem.length === 0) {
            $siblingItem = $item.prev();
            if ($siblingItem.length === 0) {
                $siblingItem = null;
            }
        }

        // Remove column item
        $item.remove();

        // Move editing to sibling item
        this.editColumn($siblingItem);

    };

    LadbEditorExport.prototype.addColumn = function (name) {

        // Create and append item
        var $item = this.appendColumnItem(true, name);

        // Edit column
        this.editColumn($item);

    };

    LadbEditorExport.prototype.init = function () {
        var that = this;

        // Generate variableDefs for formula editor
        this.variableDefs = [];
        for (var i = 0; i < this.options.vars.length; i++) {
            this.variableDefs.push({
                text: this.options.vars[i],
                displayText: i18next.t('tab.cutlist.export.' + this.options.vars[i])
            });
        }

        // Build UI

        var $header = $('<div class="ladb-editor-export-header">').append(i18next.t('tab.cutlist.export.columns'))
        this.$sortable = $('<ul class="ladb-editor-export-sortable ladb-sortable-list" />')
            .sortable(SORTABLE_OPTIONS)
        ;

        this.$element.append(
            $('<div class="ladb-editor-export-container">')
                .append($header)
                .append(this.$sortable)
        )

        // Buttons

        var $btnAdd = $('<button class="btn btn-default"><i class="ladb-opencutlist-icon-plus"></i> ' + i18next.t('tab.cutlist.export.add_column') + '</button>')
            .on('click', function () {
                that.addColumn('');
            });

        var $dropDown = $('<ul class="dropdown-menu dropdown-menu-right">');
        $dropDown.append(
            $('<li class="dropdown-header">' + i18next.t('tab.cutlist.export.add_native_columns') + '</li>')
        )
        $.each(this.options.vars, function (index, v) {
            $dropDown.append(
                $('<li>')
                    .append(
                        $('<a href="#">' + i18next.t('tab.cutlist.export.' + v) + '</a>')
                            .on('click', function () {
                                that.addColumn(v);
                            })
                    )
            )
        });

        var $btnGroup = $('<div class="btn-group">')
            .append($btnAdd)
            .append($('<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>'))
            .append($dropDown)

        var $btnContainer = $('<div style="display: inline-block" />');

        this.$element.append(
            $('<div class="ladb-editor-export-buttons" style="margin: 10px;"></div>')
                .append($btnGroup)
                .append('&nbsp;')
                .append($btnContainer)
        );

        this.$btnContainer = $btnContainer;

        // Help

        this.$helpBlock = $('<div class="col-xs-offset-1 col-xs-10"><p class="help-block text-center"><small>' + i18next.t('tab.cutlist.export.customize_help') + '</small></p></div>');
        this.$element.append(this.$helpBlock);

    };

    // PLUGIN DEFINITION
    // =======================

    function Plugin(option, params) {
        var value;
        var elements = this.each(function () {
            var $this = $(this);
            var data = $this.data('ladb.editorExport');
            var options = $.extend({}, LadbEditorExport.DEFAULTS, $this.data(), typeof option === 'object' && option);

            if (!data) {
                $this.data('ladb.editorExport', (data = new LadbEditorExport(this, options)));
            }
            if (typeof option === 'string') {
                value = data[option].apply(data, Array.isArray(params) ? params : [ params ])
            } else {
                data.init(params);
            }
        });
        return typeof value !== 'undefined' ? value : elements;
    }

    var old = $.fn.ladbEditorExport;

    $.fn.ladbEditorExport = Plugin;
    $.fn.ladbEditorExport.Constructor = LadbEditorExport;


    // NO CONFLICT
    // =================

    $.fn.ladbEditorExport.noConflict = function () {
        $.fn.ladbEditorExport = old;
        return this;
    }

}(jQuery);